import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/capture_settings_screen/capture_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/device_screen/device_screen.dart';
import 'package:ble_test/screens/ble_main_screen/meta_data_settings_screen/meta_data_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/receive_settings_screen/receive_data_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/set_password_screen/set_password_screen.dart';
import 'package:ble_test/screens/ble_main_screen/transmit_settings_screen/transmit_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/upload_settings_screen/upload_settings_screen.dart';
import 'package:ble_test/screens/capture_screen/capture_screen.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/global.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

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
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  bool isLogout = false;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // initMtuRequest();
    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (_connectionState == BluetoothConnectionState.disconnected) {
        Navigator.popUntil(context, (route) => route.isFirst);
        // Navigator.popUntil(context, (route) => route.isCurrent);
      }
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
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    onLogout();
    isLogout = false;
    roleUser = Role.NONE;
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      _services = await device.discoverServices();
      initSubscription();
      // initLastValueSubscription(_device);
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

  // init subscription
  void initSubscription() {
    for (var service in _services) {
      // log("characteristic : ${service.characteristics}");
      for (var characteristic in service.characteristics) {
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
  }

  Future initMtuRequest() async {
    try {
      await device.requestMtu(512, predelay: 0);
      Snackbar.show(ScreenSnackbar.login, "Request Mtu: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Change Mtu Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onSubscribePressed(BluetoothCharacteristic c) async {
    log("masuk sini tak ?");
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      await c.setNotifyValue(true);
      // if (c.isNotifying) {
      //   initLastValueSubscription(_device);
      // }
      Snackbar.show(ScreenSnackbar.login, "$op : Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
      log("set value notify success");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Subscribe Error:", e),
          success: false);
      log("notify set error : $e");
    }
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu Settings'),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  FeatureWidget(
                    visible: featureD.contains(roleUser),
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
                    visible: featureB.contains(roleUser),
                    title: "Capture Settings",
                    icon: const Icon(Icons.camera_alt_outlined),
                    onTap: () {
                      if (isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaptureSettingsScreen(
                              device: device,
                            ),
                          ),
                        );
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                      }
                    },
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Receive Settings",
                    icon: const Icon(Icons.download_outlined),
                    onTap: () {
                      if (isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReceiveDataSettingsScreen(device: device),
                          ),
                        );
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                      }
                    },
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Transmit Settings",
                    icon: const Icon(CupertinoIcons.paperplane),
                    onTap: () {
                      if (isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransmitSettingsScreen(device: device),
                          ),
                        );
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                      }
                    },
                  ),
                  Visibility(
                    visible: featureB.contains(roleUser),
                    child: FeatureWidget(
                      title: "Upload Settings",
                      icon: const Icon(Icons.upload_outlined),
                      onTap: () {
                        if (isConnected) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UploadSettingsScreen(device: device),
                            ),
                          );
                        } else {
                          Snackbar.showNotConnectedFalse(
                              ScreenSnackbar.blemain);
                        }
                      },
                    ),
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Meta Data Settings",
                    icon: const Icon(Icons.code),
                    onTap: () {
                      if (isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MetaDataSettingsScreen(device: device),
                          ),
                        );
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                      }
                    },
                  ),
                  // FeatureWidget(
                  //   visible: featureD.contains(roleUser),
                  //   title: "Battery",
                  //   onTap: () {
                  //     if (isConnected) {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => BatteryScreen(device: device),
                  //         ),
                  //       );
                  //     } else {
                  //       Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                  //     }
                  //   },
                  //   icon: const Icon(
                  //     CupertinoIcons.battery_charging,
                  //   ),
                  // ),

                  FeatureWidget(
                    visible: featureC.contains(roleUser),
                    title: "Device Status",
                    onTap: () {
                      if (isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceScreen(device: device),
                          ),
                        );
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                      }
                    },
                    icon: const Icon(
                      CupertinoIcons.device_phone_portrait,
                    ),
                  ),
                  FeatureWidget(
                    visible: featureC.contains(roleUser),
                    title: "Set Password",
                    onTap: () {
                      if (isConnected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SetPasswordScreen(device: device),
                          ),
                        );
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                      }
                    },
                    icon: const Icon(
                      Icons.lock_outlined,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CaptureScreen(device: device),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Capture",
                            style: GoogleFonts.readexPro(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () async {
                      await storage.deleteAll();

                      if (isConnected) {
                        List<int> list = utf8.encode("logout!");
                        Uint8List bytes = Uint8List.fromList(list);
                        BLEUtils.funcWrite(bytes, "Logout success", device);
                        // ini harusnya dengan disconnect juga
                        onDisconnectPressed();
                        if (mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      } else {
                        Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                        await Future.delayed(const Duration(seconds: 2));
                        if (mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Logout",
                            style: GoogleFonts.readexPro(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  )
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
    this.visible = true,
  });

  final String title;
  final void Function()? onTap;
  final Widget icon;
  final bool? visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible ?? true,
      child: GestureDetector(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      title,
                      style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
