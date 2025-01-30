import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/global.dart';
import 'package:ble_test/utils/salt.dart';
import 'package:ble_test/widgets/scan_result_tile.dart';
import 'package:ble_test/widgets/system_device_tile.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../utils/ble.dart';
import '../../utils/crypto/crypto.dart';
import '../../utils/snackbar.dart';

class SearchScreen extends StatefulWidget {
  final String userRole;
  final String password;
  const SearchScreen({
    Key? key,
    required this.userRole,
    required this.password,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  late String userRole, password;
  late SimpleFontelicoProgressDialog pd;

  // for connection ble
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  StreamSubscription<List<int>>? _lastValueSubscription;
  List<int> valueHandshake = [];
  List<int> _value = [];
  bool isSearchScreen = true;

  @override
  void initState() {
    super.initState();
    userRole = widget.userRole;
    password = widget.password;
    pd =
        SimpleFontelicoProgressDialog(context: context, barrierDimisable: true);

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (isSearchScreen) {
        _scanResults = results;
      }
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(
          ScreenSnackbar.searchscreen, prettyException("Scan Error:", e),
          success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
    _scanResults.clear();
    _systemDevices.clear();
    onScanPressed();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    isSearchScreen = false;
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      // `withServices` is required on iOS for privacy purposes, ignored on android.
      var withServices = [Guid("180f")]; // Battery Level Service
      if (isSearchScreen) {
        _systemDevices = await FlutterBluePlus.systemDevices(withServices);
      }
      log("system devices resultnya : $_systemDevices, ${_systemDevices.length}, ${_systemDevices[0].advName}");
    } catch (e) {
      // ini biasanya bisa diabaikans
      log("error scan system connect to this device : $e");
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      log("error scan result device : $e");
      if (e.toString() ==
          "RangeError (index): Invalid value: Valid value range is empty: 0") {
      } else {
        Snackbar.show(ScreenSnackbar.searchscreen,
            prettyException("Start Scan Error:", e),
            success: false);
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.searchscreen, prettyException("Stop Scan Error:", e),
          success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) async {
    log("SCAN  DEVICE : $device");
    log("name : ${device.advName}");
    log("remote id : ${device.remoteId}");
    pd.show(message: "Login process . . .");
    bool konek = await device.connectAndUpdateStream().catchError((e) {
      pd.hide();
      log("FAILED CONNECT search screen");

      Snackbar.show(
          ScreenSnackbar.searchscreen, prettyException("Connect Error:", e),
          success: false);
      if (e != null) {
        return false;
      }
      return true;
    });
    log("SUCCESS CONNECT search screen : $konek");
    Future.delayed(const Duration(seconds: 4, milliseconds: 500));

    // listen for connection state
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        _connectionState = state;
        if (mounted) {
          setState(() {});
        }
      },
    );
    log("isconnected : $isConnected");

    /// disini harusnya ada pengecekan connected
    await initDiscoverServices(device);

    /// DO HANDSHAKE
    List<int> list = utf8.encode("handshake?");
    Uint8List bytes = Uint8List.fromList(list);
    BLEUtils.funcWrite(bytes, "Handshake Success", device);

    // await for handshake cause handshake is importanto
    await Future.delayed(const Duration(seconds: 2));
    // LOGIN
    if (valueHandshake.isNotEmpty) {
      log("login process search screen . . .");
      loginProcess(device);
    } else {
      pd.hide();
      Snackbar.show(
          ScreenSnackbar.searchscreen, "Login Failed! Value handshake is empty",
          success: false);
    }
  }

  loginProcess(BluetoothDevice device) async {
    List<int> forIV = valueHandshake + SALT1;
    List<int> forKey1 = valueHandshake + SALT2;
    List<int> forKey2 = valueHandshake + SALT3;

    String iv = md5.convert(forIV).toString();
    String key =
        md5.convert(forKey1).toString() + md5.convert(forKey2).toString();

    String resultAes256 =
        await CryptoAES256().encryptCustomV2(key, iv, password);

    log("login=$userRole;$resultAes256");
    String commLogin = "login=$userRole;$resultAes256";
    List<int> list = utf8.encode(commLogin);
    Uint8List bytes = Uint8List.fromList(list);

    await BLEUtils.funcWrite(bytes, "Command login success", device);
    pd.hide();
  }

  Future initDiscoverServices(BluetoothDevice device) async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      _services = await device.discoverServices();
      initSubscription(device);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.searchscreen,
          prettyException("Discover Services Error:", e),
          success: false);
      log(e.toString());
    }
    if (mounted) {
      setState(() {});
    }
  }

  initLastValueSubscription(BluetoothCharacteristic c, BluetoothDevice device) {
    // ini disini harusnya ada algoritm untuk ambil data value notify
    // ketika handshake? ke write
    try {
      // log("notify : ${characters.properties.notify}, isNotifying : $isNotifying");
      lastValueSubscription = c.lastValueStream.listen(
        (value) {
          log("is notifying ga nih : ${c.isNotifying}");
        },
        cancelOnError: true,
      );

      lastValueSubscription!.onData((data) {
        if (c.properties.notify && isSearchScreen) {
          lastValueG = data;
          log("_VALUE LOGIN : $lastValueG");

          /// this is for login
          if (lastValueG.length == 1 && lastValueG[0] == 1) {
            pd.hide();
            if (userRole == "admin") {
              roleUser = Role.ADMIN;
            } else if (userRole == "operator") {
              roleUser = Role.OPERATOR;
            } else if (userRole == "guest") {
              roleUser = Role.GUEST;
            }
            isSearchScreen = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BleMainScreen(
                  device: device,
                ),
              ),
            ).then((value) {
              isSearchScreen = true;
            });
          } else if (lastValueG.length == 1 && lastValueG[0] == 0) {
            Snackbar.show(
              ScreenSnackbar.searchscreen,
              "Login Failed",
              success: false,
            );
          }

          /// handshake
          if (lastValueG.length > 1) {
            log("LENGTH HANDSHAKE : ${lastValueG.length}");
            valueHandshake = lastValueG;
          }
          if (mounted) {
            setState(() {});
          }
        }
      });
      // _lastValueSubscription.cancel();
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.searchscreen, prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  void initSubscription(BluetoothDevice device) {
    for (var service in _services) {
      // log("characteristic : ${service.characteristics}");
      for (var characteristic in service.characteristics) {
        // log("ini true kah : ${characteristic.properties.notify}");
        if (characteristic.properties.notify) {
          // await characteristic
          subscribeProcess(characteristic, device);
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  Future subscribeProcess(
      BluetoothCharacteristic c, BluetoothDevice device) async {
    log("masuk sini tak ?");
    try {
      await c.setNotifyValue(true);
      if (c.isNotifying) {
        initLastValueSubscription(c, device);
      }
      if (c.properties.read) {
        await c.read();
      }
      log("set value notify success");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.searchscreen, prettyException("Subscribe Error:", e),
          success: false);
      log("notify set error : $e");
    }
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
        onPressed: onScanPressed,
        child: const Icon(Icons.search),
        // child: const Text(
        //   "SCAN",
        // ),
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    _systemDevices.removeWhere((element) => element.platformName.isNotEmpty);
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => onConnectPressed(d),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    // log("resultnya : $_scanResults");
    _scanResults.removeWhere((element) {
      return element.device.platformName.isEmpty;
    });
    return _scanResults.map(
      (r) {
        return ScanResultTile(
          result: r,
          onTap: () => onConnectPressed(r.device),
        );
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeySearchScreen,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Scan Devices',
            style: GoogleFonts.readexPro(),
          ),
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }

  // connected
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
