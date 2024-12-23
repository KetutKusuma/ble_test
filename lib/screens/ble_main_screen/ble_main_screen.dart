import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/screens/login_hanshake_screen/login_handshake_screen.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../utils/converter/bytes_convert.dart';

class BleMainScreen extends StatefulWidget {
  final BluetoothDevice device;

  const BleMainScreen({super.key, required this.device});

  @override
  State<BleMainScreen> createState() => _BleMainScreenState();
}

class _BleMainScreenState extends State<BleMainScreen> {
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<List<int>> _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  bool isLogout = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (_connectionState == BluetoothConnectionState.disconnected) {
        Navigator.pop(context);
        // Navigator.popUntil(context, (route) => route.isCurrent);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _connectionStateSubscription.cancel();
    // _lastValueSubscription.cancel();
    onLogout();
    isLogout = false;
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  onLogout() {
    List<int> list = utf8.encode("logout!");
    Uint8List bytes = Uint8List.fromList(list);
    funcWrite(bytes, "Success Logout");
    isLogout = true;
  }

  Future<void> funcWrite(Uint8List bytes, String msg) async {
    for (var service in device.servicesList) {
      for (var element in service.characteristics) {
        // log("characteristic : $element");
        if (element.properties.write && isConnected) {
          await element.write(bytes);
          log("message : $msg");
          // if (mounted) {
          //   Snackbar.show(ScreenSnackbar.login, msg, success: true);
          // }
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

  /// ===== for connection ===================
  Future onConnectPressed() async {
    try {
      await device.connectAndUpdateStream();
      // initDiscoverServices();
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
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.login, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.login, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.login, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Disconnect Error:", e),
          success: false);
      log(e.toString());
    }
  }

  // Future onSubscribePressed(BluetoothCharacteristic c) async {
  //   log("masuk sini tak ?");
  //   try {
  //     String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
  //     await c.setNotifyValue(c.isNotifying == false);
  //     // if (c.isNotifying) {
  //     //   initLastValueSubscription(device);
  //     // }
  //     Snackbar.show(ScreenSnackbar.login, "$op : Success", success: true);
  //     if (c.properties.read) {
  //       await c.read();
  //     }
  //     log("set value notify success");
  //     if (mounted) {
  //       setState(() {
  //         isNotifying = c.isNotifying;
  //       });
  //     }
  //   } catch (e) {
  //     Snackbar.show(
  //         ScreenSnackbar.login, prettyException("Subscribe Error:", e),
  //         success: false);
  //     log("notify set error : $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyBleMain,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu Settings'),
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
                  FeatureWidget(
                    title: "Admin Settings",
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminSettingsScreen(
                              device: device,
                            ),
                          ));
                    },
                  ),
                  FeatureWidget(
                    title: "Capture Settings",
                    icon: const Icon(Icons.camera_alt_outlined),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    title: "Receive Settings",
                    icon: const Icon(Icons.download_outlined),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    title: "Transmit Settings",
                    icon: const Icon(Icons.wifi),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    title: "Upload Settings",
                    icon: const Icon(Icons.upload_outlined),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    title: "Meta Data Settings",
                    icon: const Icon(Icons.code),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureWidget extends StatelessWidget {
  const FeatureWidget({
    super.key,
    required this.title,
    required this.onTap,
    required this.icon,
  });

  final String title;
  final void Function()? onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              icon,
              const SizedBox(
                width: 5,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
