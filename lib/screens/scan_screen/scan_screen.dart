import 'dart:async';
import 'dart:developer';

import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/login_hanshake_screen/login_handshake_screen.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/widgets/scan_result_tile.dart';
import 'package:ble_test/widgets/system_device_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../utils/snackbar.dart';

class ScanScreenX extends StatefulWidget {
  final String userRole;
  final String password;
  const ScanScreenX({
    Key? key,
    required this.userRole,
    required this.password,
  }) : super(key: key);

  @override
  State<ScanScreenX> createState() => _ScanScreenXState();
}

class _ScanScreenXState extends State<ScanScreenX> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ScreenSnackbar.scan, prettyException("Scan Error:", e),
          success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      // `withServices` is required on iOS for privacy purposes, ignored on android.
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
      log("system devices resultnya : $_systemDevices, ${_systemDevices.length}, ${_systemDevices[0].advName}");
    } catch (e) {
      if (e.toString() ==
          "RangeError (index): Invalid value: Valid value range is empty: 0") {
        Snackbar.show(ScreenSnackbar.scan, "System Devices is Not Found",
            success: false);
      } else {
        Snackbar.show(
          ScreenSnackbar.scan,
          prettyException("System Devices Error:", e),
          success: false,
        );
      }
      print(e);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      if (e.toString() ==
          "RangeError (index): Invalid value: Valid value range is empty: 0") {
        Snackbar.show(ScreenSnackbar.scan, "Start Scan Result is Not Found",
            success: false);
      } else {
        Snackbar.show(
            ScreenSnackbar.scan, prettyException("Start Scan Error:", e),
            success: false);
      }
      print(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ScreenSnackbar.scan, prettyException("Stop Scan Error:", e),
          success: false);
      print(e);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ScreenSnackbar.scan, prettyException("Connect Error:", e),
          success: false);
    });
    MaterialPageRoute route = MaterialPageRoute(
        // builder: (context) => DeviceScreen(device: device),
        // builder: (context) => LoginHandshakeScreen(device: device),
        builder: (context) => BleMainScreen(device: device),
        settings: const RouteSettings(name: '/LoginShakeScreen'));
    Navigator.of(context).push(route);
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
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
        child: const Text(
          "SCAN",
        ),
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                // builder: (context) => BleMainScreen(device: d),
                builder: (context) => LoginHandshakeScreen(device: d),
                // settings: const RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    // log("resultnya : $_scanResults");
    return _scanResults.map((r) {
      // if (r.advertisementData.serviceData.isEmpty) {
      //   return const SizedBox();
      // } else {
      //   return ScanResultTile(
      //     result: r,
      //     onTap: () => onConnectPressed(r.device),
      //   );
      // }
      return ScanResultTile(
        result: r,
        onTap: () => onConnectPressed(r.device),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyScan,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Devices'),
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
