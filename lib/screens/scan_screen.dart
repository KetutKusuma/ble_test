import 'dart:async';
import 'dart:developer';

import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/login_hanshake_screen/login_handshake_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.addListener(_onTextChanged);
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
                builder: (context) => DeviceScreen(device: d),
                settings: const RouteSettings(name: '/DeviceScreen'),
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

  void _onTextChanged() {
    String text =
        _searchController.text.replaceAll(":", ""); // Remove existing colons
    String formattedText = "";

    // Add colon after every 2 characters
    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        formattedText += ":";
      }
    }

    // Prevent unnecessary updates (cursor position fixes)
    if (formattedText != _searchController.text) {
      final cursorPosition = _searchController.selection.baseOffset;
      _searchController.value = _searchController.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(
            offset: cursorPosition +
                (formattedText.length - _searchController.text.length)),
      );
    }
  }

  void scanForDevices(String targetMacAddress) {
    log("Scanning for devices...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    bool isFound = false;

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      log("LISTENNNING");
      for (ScanResult result in results) {
        // log("device remote id : ${result.device} == ${targetMacAddress.toUpperCase()}");
        // Match device ID with the target MAC address
        if (result.device.remoteId.toString().toUpperCase() ==
            targetMacAddress.toUpperCase()) {
          log("Target Device Found: ${result.device}");

          isFound = true;
          FlutterBluePlus.stopScan(); // Stop scanning
          onConnectPressed(result.device);
          _scanResultsSubscription.cancel();
          break;
        }
      }
    });

    log("isFound : $isFound");
    if (isFound == false) {
      Snackbar.show(ScreenSnackbar.scan, "Target Device Not Found",
          success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyScan,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Search"),
                      content: Form(
                        child: TextFormField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: "Enter MAC Addresses",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20)
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _searchController.clear();
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_searchController.text.isNotEmpty &&
                                _searchController.text.length > 16) {
                              log("search text : ${_searchController.text}");
                              scanForDevices(_searchController.text);

                              Navigator.pop(context);
                              _searchController.clear();
                            } else {
                              Snackbar.show(ScreenSnackbar.scan,
                                  "Please enter a valid MAC address",
                                  success: false);
                            }
                          },
                          child: const Text("Search"),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.search,
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              // ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
