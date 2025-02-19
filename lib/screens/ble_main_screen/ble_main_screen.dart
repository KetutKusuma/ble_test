import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_radio_checker.dart';
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
import 'package:ble_test/screens/radio_test_as_transmit/radio_test_as_transmit.dart';
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
import 'package:provider/provider.dart';

class BleMainScreen extends StatefulWidget {
  final BluetoothDevice device;

  const BleMainScreen({super.key, required this.device});

  @override
  State<BleMainScreen> createState() => _BleMainScreenState();
}

class _BleMainScreenState extends State<BleMainScreen> {
  late BLEProvider bleProvider;
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
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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
    device.disconnect();
    // funcWrite(bytes, "Success Logout");
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

  Future<bool?> _showAdmitRadioReceiveDialog(
      BuildContext context, String msg) async {
    bool? selectedValue = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(msg),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true); // Return true
              },
              child: const Text('Ya'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, false); // Return false
              },
              child: const Text('Tidak'),
            ),
          ],
        );
      },
    );

    return selectedValue;
  }

  Future<bool> _showStopRadioReceiveDialog(BuildContext context) async {
    bool? selectedValue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            "Sekarang radio sedang mendengarkan, tekan tombol stop untuk menghentikan radio",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true); // Return true
              },
              child: const Text(
                'Stop',
              ),
            ),
          ],
        );
      },
    );
    return selectedValue ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Menu'),
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
                    title: "Pengaturan Admin",
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
                    title: "Pengaturan Pengambilan Gambar",
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
                    title: "Pengaturan Penerimaan Data",
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
                    title: "Pengaturan Pengiriman Data",
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
                      title: "Pengaturan Unggah Data",
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
                    title: "Pengaturan Meta Data",
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
                  Visibility(
                    visible: featureC.contains(roleUser),
                    child: FeatureWidget(
                      visible: featureC.contains(roleUser),
                      title: "Status Perangkat",
                      onTap: () {
                        if (isConnected) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeviceScreen(device: device),
                            ),
                          );
                        } else {
                          Snackbar.showNotConnectedFalse(
                              ScreenSnackbar.blemain);
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.device_phone_portrait,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: featureA.contains(roleUser),
                    child: FeatureWidget(
                      title: "Tes Radio sebagai Penerima",
                      onTap: () async {
                        bool? input = await _showAdmitRadioReceiveDialog(
                            context, "Mulai tes radio sebagai penerima?");
                        if (input != null) {
                          if (input == true) {
                            // lakukan start test radio sebagai penerima
                            // muncul pop uup
                            // jika selesai pencet tombol, lakukan stop test radio sebagai penerima

                            BLEResponse resBLE = await CommandRadioChecker()
                                .radioTestAsReceiverStart(bleProvider);

                            if (!resBLE.status) {
                              Snackbar.show(
                                  ScreenSnackbar.blemain, resBLE.message,
                                  success: false);
                              return;
                            }

                            // ignore: use_build_context_synchronously
                            bool input =
                                await _showStopRadioReceiveDialog(context);
                            if (input == true) {
                              BLEResponse resBLE = await CommandRadioChecker()
                                  .radioTestAsReceiverStop(bleProvider);
                              Snackbar.show(
                                  ScreenSnackbar.blemain, resBLE.message,
                                  success: resBLE.status);
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.call_received_rounded),
                    ),
                  ),
                  Visibility(
                    visible: featureA.contains(roleUser),
                    child: FeatureWidget(
                      title: "Tes Radio sebagai Pengirim",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RadioTestAsTransmit(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_outward_rounded,
                      ),
                    ),
                  ),
                  FeatureWidget(
                    visible: featureC.contains(roleUser),
                    title: "Ubah Password",
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
                            CupertinoIcons.camera,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Pengambilan Gambar",
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
                            "Keluar",
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.contain,
                          child: icon,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        flex: 8,
                        child: Text(
                          title,
                          style: GoogleFonts.readexPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
