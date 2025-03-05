import 'dart:async';
import 'package:ble_test/untukuploadplaystore/blemainscreen.dart';
import 'package:ble_test/widgets/scan_result_tile.dart';
import 'package:ble_test/widgets/system_device_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../utils/snackbar.dart';

class SearchScreenTest extends StatefulWidget {
  const SearchScreenTest({
    Key? key,
  }) : super(key: key);

  @override
  State<SearchScreenTest> createState() => _SearchScreenTestState();
}

class _SearchScreenTestState extends State<SearchScreenTest> {
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

    addCustomScanResult();
  }

  void addCustomScanResult() {
    // Creating a custom BluetoothDevice
    BluetoothDevice customDevice = BluetoothDevice(
      remoteId:
          const DeviceIdentifier("00:11:22:33:44:55"), // Example MAC Address
    );

    // Creating custom AdvertisementData
    AdvertisementData advertisementData = AdvertisementData(
      advName: "My BLE Device",
      appearance: 10,
      connectable: true,
      txPowerLevel: 10,
      manufacturerData: {},
      serviceData: {},
      serviceUuids: [],
    );

    // Creating custom ScanResult
    ScanResult customScanResult = ScanResult(
      device: customDevice,
      advertisementData: advertisementData,
      rssi: -50, // Example RSSI value
      timeStamp: DateTime.now(),
    );

    // Adding to the list
    _scanResults.add(customScanResult);

    // Debug print
    print("Custom ScanResult added: ${customScanResult.device.platformName}");
  }

  @override
  void dispose() {
    super.dispose();
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
        onPressed: () {},
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
        onPressed: () {},
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
            onOpen: () => (d),
            onConnect: () => (d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    // log("resultnya : $_scanResults");

    return _scanResults.map(
      (r) {
        return ScanResultTile(
          result: r,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BleMainScreenTest(device: r.device),
              )),
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
