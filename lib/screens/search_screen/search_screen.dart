import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/ble-v2/command.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/tes_coba.dart';
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
import 'package:provider/provider.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../ble-v2/ble.dart';
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
  late BLEProvider bleProvider;

  @override
  void initState() {
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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
    pd.show(message: "Proses masuk ...");
    await bleProvider.connect(device);
    Future.delayed(const Duration(seconds: 2, milliseconds: 500));
    // login new v2
    BLEResponse resHandshake = await Command().handshake(device, bleProvider);
    log("resHandshake : $resHandshake");
    if (resHandshake.status == false) {
      return;
    }
    List<int> challenge = resHandshake.data!;
    BLEResponse resLogin = await Command()
        .login(device, bleProvider, userRole, password, challenge);
    log("resLogin : $resLogin");
    pd.hide();
    if (resLogin.status == false) {
      Snackbar.show(
        ScreenSnackbar.searchscreen,
        resLogin.message,
        success: false,
      );
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BleMainScreen(device: device),
          ),
        );
      }
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
            // onConnect: () {
            //   Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => TesCaraBaru(
            //           device: d,
            //         ),
            //       ));
            // },
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
          // onTap: () {
          //   Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => TesCaraBaru(
          //           device: r.device,
          //         ),
          //       ));
          // },
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
            'Pindai Perangkat',
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
