import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/utils/crypto.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/salt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../utils/snackbar.dart';

class LoginHandshakeScreen extends StatefulWidget {
  final BluetoothDevice device;

  const LoginHandshakeScreen({super.key, required this.device});

  @override
  State<LoginHandshakeScreen> createState() => _LoginHandshakeScreenState();
}

class _LoginHandshakeScreenState extends State<LoginHandshakeScreen> {
  int? _mtuSize;
  int? rssi;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  // bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;
  late BluetoothDevice _device;
  final TextEditingController _userRoleTxtController = TextEditingController();
  final TextEditingController _passwordTxtController = TextEditingController();
  List<int> _value = [];

  /// ===== for handshake =====
  bool isWriteHandshake = false;

  /// ===== for login form =====
  bool isShowLoginForm = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _device = widget.device;

    _connectionStateSubscription =
        _device.connectionState.listen((state) async {
      _connectionState = state;
    });

    _mtuSubscription = _device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = _device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription = _device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    initLastValueSubscription(_device);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _lastValueSubscription.cancel();
    isWriteHandshake = false;
  }

  initLastValueSubscription(BluetoothDevice device) {
    // ini disini harusnya ada algoritm untuk ambil data value notify
    // ketika handshake? ke write
    for (var service in device.servicesList) {
      for (var characters in service.characteristics) {
        _lastValueSubscription = characters.lastValueStream.listen((value) {
          if (characters.properties.notify) {
            _value = value;
            if (_value.isNotEmpty && isWriteHandshake) {
              isShowLoginForm = true;
            }
            if (mounted) {
              setState(() {});
            }
          }
        });
      }
    }
  }

  /// GET
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_device.remoteId}'), actions: [
        Row(children: [
          if (_isConnecting || _isDisconnecting) buildSpinner(context),
          TextButton(
              onPressed: _isConnecting
                  ? onCancelPressed
                  : (isConnected ? onDisconnectPressed : onConnectPressed),
              child: Text(
                _isConnecting
                    ? "CANCEL"
                    : (isConnected ? "DISCONNECT" : "CONNECT"),
                style: Theme.of(context)
                    .primaryTextTheme
                    .labelLarge
                    ?.copyWith(color: Colors.white),
              ))
        ]),
      ]),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                Text("Value : $_value"),
                Stack(
                  children: [
                    !isConnected
                        ?
                        // kalau disconnect
                        Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: Colors.grey.shade400,
                          )
                        :
                        // kalau connect
                        const SizedBox(),
                    Column(
                      children: [
                        // handshake
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                if (isConnected) {
                                  List<int> list = utf8.encode("id?");
                                  Uint8List bytes = Uint8List.fromList(list);

                                  /// get characteristic write
                                  isWriteHandshake = true;
                                  await funcWrite(bytes);
                                  setState(() {});
                                }
                              } catch (e) {
                                Snackbar.show(ABC.c, "Error Handshake : $e",
                                    success: false);
                              }
                            },
                            child: const Text(
                              "Handshake",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        // form login
                        Stack(
                          children: [
                            (!isShowLoginForm)
                                ? Container(
                                    height: double.infinity,
                                    width: double.infinity,
                                    color: Colors.grey.shade400,
                                  )
                                : const SizedBox(),
                            Column(
                              children: [
                                TextFormField(
                                  controller: _userRoleTxtController,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  controller: _passwordTxtController,
                                ),
                                const SizedBox(
                                  height: 30,
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      if (isConnected) {
                                        // create iv for AES256
                                        String iv = md5
                                            .convert(_value + SALT1)
                                            .toString();
                                        String key = md5
                                                .convert(_value + SALT2)
                                                .toString() +
                                            md5
                                                .convert(_value + SALT3)
                                                .toString();

                                        // create key for AES256
                                        String resultAes256 = CryptoAES256()
                                            .encryptData(key, iv,
                                                _passwordTxtController.text);

                                        List<int> list = utf8.encode(
                                            "login=$_userRoleTxtController, $resultAes256");
                                        Uint8List bytes =
                                            Uint8List.fromList(list);

                                        /// get characteristic write
                                        await funcWrite(bytes);
                                      }
                                    } catch (e) {
                                      Snackbar.show(
                                          ABC.c, "Error Handshake : $e",
                                          success: false);
                                    }
                                  },
                                  child: const Text("Login"),
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> funcWrite(Uint8List bytes) async {
    for (var service in _device.servicesList) {
      for (var element in service.characteristics) {
        if (element.properties.write) {
          _value.clear();
          await element.write(bytes);
          Snackbar.show(ABC.c, "Handsake Success", success: true);
          break;
        }
      }
    }
  }

  Widget buildSpinner(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  /// for connection
  Future onConnectPressed() async {
    try {
      await _device.connectAndUpdateStream();
      // listenToDeviceTest(device);
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await _device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await _device.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
      log(e.toString());
    }
  }
}
