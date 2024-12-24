import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:ble_test/utils/crypto/crypto.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/salt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../utils/snackbar.dart';

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
  late StreamSubscription<List<int>>? _lastValueSubscription;
  late BluetoothDevice _device;
  final TextEditingController _userRoleTxtController = TextEditingController();
  final TextEditingController _passwordTxtController = TextEditingController();
  List<int> _value = [];
  bool isLogin = false;

  /// ===== for notify =====
  bool isNotifying = false;

  /// ===== for handshake =====
  bool isWriteHandshake = false;

  /// ===== for login form =====
  bool isShowLoginForm = false;

  // global key
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    log("MASUK LOGIN HANDSHAKE SCREEN");
    _device = widget.device;

    _connectionStateSubscription =
        _device.connectionState.listen((state) async {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
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

    initDiscoverServices();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isWriteHandshake = false;
    isLogin = false;
  }

  initLastValueSubscription(BluetoothDevice device) {
    // ini disini harusnya ada algoritm untuk ambil data value notify
    // ketika handshake? ke write
    try {
      for (var service in device.servicesList) {
        for (var characters in service.characteristics) {
          log("notify : ${characters.properties.notify}, isNotifying : $isNotifying");
          _lastValueSubscription = characters.lastValueStream.listen(
            (value) {
              log("is notifying ga nih : ${characters.isNotifying}");
              if (characters.properties.notify) {
                isNotifying = characters.isNotifying;
                _value = value;
                log("_VALUE : $_value");
                if (_value.isNotEmpty && isWriteHandshake) {
                  isShowLoginForm = true;
                }

                /// this is for login
                if (_value.length == 1 && isLogin) {
                  bool loginRes = BytesConvert.bytesToBool(value);
                  if (loginRes) {
                    if (mounted) {
                      isLogin = false;
                      if (mounted) {
                        setState(() {});
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BleMainScreen(
                              device: _device,
                            ),
                          ));
                    }
                  } else {
                    Snackbar.show(ScreenSnackbar.login, "Login Failed",
                        success: false);
                  }
                }
                // log("uhuy : ${BytesConvert.bytesToBool(value)} ${value.length}");
                if (mounted) {
                  setState(() {});
                }
              }
            },
            cancelOnError: true,
          );
          // _lastValueSubscription.cancel();
        }
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      _services = await _device.discoverServices();
      initLastValueSubscription(_device);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Discover Services Error:", e),
          success: false);
      log(e.toString());
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await _device.requestMtu(512, predelay: 1);
      Snackbar.show(ScreenSnackbar.login, "Request Mtu: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Change Mtu Error:", e),
          success: false);
      log(e.toString());
    }
  }

  /// GET
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  @override
  Widget build(BuildContext context) {
    log("isConnected : $isConnected");
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyLogin,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('${_device.remoteId}'),
          actions: [
            Row(
              children: [
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
                  ),
                )
              ],
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "MTU size : $_mtuSize",
                            ),
                            IconButton(
                                onPressed: () {
                                  onRequestMtuPressed();
                                },
                                icon: const Icon(CupertinoIcons.settings))
                          ],
                        ),
                        TextButton(
                            onPressed: () async {
                              for (var service in _services) {
                                // log("characteristic : ${service.characteristics}");
                                for (var characteristic
                                    in service.characteristics) {
                                  // log("ini true kah : ${characteristic.properties.notify}");
                                  if (characteristic.properties.notify) {
                                    // await characteristic
                                    onSubscribePressed(characteristic);
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                }
                              }
                            },
                            child:
                                Text(isNotifying ? "Unsubscribe" : "Subscribe"))
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text("Value : $_value"),
                  ),
                  Column(
                    children: [
                      // handshake
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              if (isConnected) {
                                List<int> list = utf8.encode("handshake?");
                                Uint8List bytes = Uint8List.fromList(list);
                                log("BYTES : $bytes");

                                log("Device : $_device");
                                funcWrite(bytes, "Handshake commmand success");
                              }
                            } catch (e) {
                              Snackbar.show(
                                  ScreenSnackbar.login, "Error Handshake : $e",
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            TextFormField(
                              controller: _userRoleTxtController,
                              decoration: InputDecoration(
                                hintText: 'User Role',
                                border: InputBorder.none, // Removes all borders
                                filled:
                                    true, // Optional: Adds a background color
                                fillColor: Colors
                                    .grey[200], // Optional: Background color
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0, // Adjusts the height
                                  horizontal:
                                      12.0, // Adjusts padding inside the field
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            TextFormField(
                              controller: _passwordTxtController,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                border: InputBorder.none, // Removes all borders
                                filled:
                                    true, // Optional: Adds a background color
                                fillColor: Colors
                                    .grey[200], // Optional: Background color
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0, // Adjusts the height
                                  horizontal:
                                      12.0, // Adjusts padding inside the field
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  log("isConnected : $isConnected");
                                  if (isConnected) {
                                    if (_value.length == 1) {
                                      Snackbar.show(ScreenSnackbar.login,
                                          "Click handshake first before login",
                                          success: false);
                                    } else {
                                      log("VALUE SEBELUM + : $_value");
                                      log("SALT1 SEBELUM + : $SALT1");

                                      String hexString = _value
                                          .map((num) => num.toRadixString(16)
                                              .padLeft(2, '0'))
                                          .join();
                                      log("hex : $hexString");
                                      List<int> val = utf8.encode(hexString);
                                      // List<int> _value =

                                      List<int> forIV = val + SALT1;
                                      log("for iv : $forIV");
                                      List<int> forKey1 = val + SALT2;
                                      List<int> forKey2 = val + SALT3;

                                      log("process iv");
                                      String iv = md5.convert(forIV).toString();
                                      log("process key");
                                      log("key1 ${md5.convert(forKey1).toString()}");
                                      log("key2 ${md5.convert(forKey2).toString()}");
                                      String key =
                                          md5.convert(forKey1).toString() +
                                              md5.convert(forKey2).toString();

                                      log("iv : ${iv.length} --> ${iv.length / 2} byte");
                                      log("key : ${key.length} --> ${key.length / 2} byte");

                                      // create key for AES256
                                      log("process aes256");
                                      String resultAes256 = await CryptoAES256()
                                          .encryptCustomV2(key, iv,
                                              _passwordTxtController.text);

                                      String commLogin =
                                          "login=${_userRoleTxtController.text};$resultAes256";
                                      List<int> list = utf8.encode(commLogin);
                                      Uint8List bytes =
                                          Uint8List.fromList(list);
                                      isLogin = true;

                                      await funcWrite(
                                          bytes, "Command login success");
                                      // /// get characteristic write
                                      // for (var service
                                      //     in _device.servicesList) {
                                      //   for (var element
                                      //       in service.characteristics) {
                                      //     // log("characteristic : $element");
                                      //     if (element.properties.write) {
                                      //       _value.clear();
                                      //       await element.write(bytes);
                                      //       // Snackbar.show(ScreenSnackbar.login,
                                      //       //     "Login Success",
                                      //       //     success: true);
                                      //       break;
                                      //     }
                                      //   }
                                      // }
                                    }
                                  } else {
                                    Snackbar.show(ScreenSnackbar.login,
                                        "Device is not connected",
                                        success: false);
                                  }
                                } catch (e) {
                                  Snackbar.show(
                                      ScreenSnackbar.login, "Error Login : $e",
                                      success: false);
                                  log("Error login : $e");
                                }
                              },
                              child: const Text("Login"),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> funcWrite(Uint8List bytes, String msg) async {
    try {
      for (var service in _device.servicesList) {
        for (var element in service.characteristics) {
          // log("characteristic : $element");
          if (element.properties.write) {
            _value.clear();
            await element.write(bytes);
            log("message : $msg");
            // if (mounted) {
            //   Snackbar.show(ScreenSnackbar.login, msg, success: true);
            // }
            break;
          }
        }
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.login, "Error Write : $e", success: false);
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

  /// ===== for connection ===================
  Future onConnectPressed() async {
    try {
      await _device.connectAndUpdateStream();
      // listenToDeviceTest(device);
      initDiscoverServices();
      // initLastValueSubscription(_device);
      Snackbar.show(ScreenSnackbar.login, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(
            ScreenSnackbar.login, prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await _device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.login, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.login, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await _device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.login, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Disconnect Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onSubscribePressed(BluetoothCharacteristic c) async {
    log("masuk sini tak ?");
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      log("otw set value notify : ${c.isNotifying}, $isNotifying");
      await c.setNotifyValue(c.isNotifying == false);
      // if (c.isNotifying) {
      //   initLastValueSubscription(_device);
      // }
      Snackbar.show(ScreenSnackbar.login, "$op : Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
      log("set value notify success");
      if (mounted) {
        setState(() {
          isNotifying = c.isNotifying;
        });
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Subscribe Error:", e),
          success: false);
      log("notify set error : $e");
    }
  }
}
