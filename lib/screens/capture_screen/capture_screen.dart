import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CaptureScreen extends StatefulWidget {
  final BluetoothDevice device;

  const CaptureScreen({super.key, required this.device});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  final bool _isConnecting = false;
  final bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String statusTxt = '-',
      destinationEnableTxt = '-',
      destinationIdTxt = '-',
      transmitScheduleTxt = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();

  // this is for nttx
  bool isCaptureScreen = true;

  // this is for the image
  bool isCaptureTransmit = false;
  List<int> imageBytes = [];
  List<int> listChunk = [];

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        _connectionState = state;
        if (_connectionState == BluetoothConnectionState.disconnected) {
          Navigator.pop(
            context,
          );
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    initDiscoverServices();
  }

  @override
  void dispose() {
    super.dispose();
    isCaptureTransmit = false;
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 4));
    if (isConnected) {
      try {
        _services = await device.discoverServices();
        initLastValueSubscription(device);
      } catch (e) {
        Snackbar.show(ScreenSnackbar.transmitsettings,
            prettyException("Discover Services Error:", e),
            success: false);
        log(e.toString());
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  initLastValueSubscription(BluetoothDevice device) {
    try {
      for (var service in device.servicesList) {
        for (var characters in service.characteristics) {
          _lastValueSubscription = characters.lastValueStream.listen(
            (value) {
              if (characters.properties.notify && isCaptureScreen) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;

                log("VALUE : $_value, ${_value.length}");

                /// this is for receive image
                if (isCaptureTransmit) {}

                if (mounted) {
                  setState(() {});
                }
              }
            },
            cancelOnError: true,
          );
        }
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.transmitsettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future<String?> _showInputDialog(
      TextEditingController controller, String inputTitle) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Value $inputTitle"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Enter a value',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
                } else {}
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarCapture,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Capture Screen"),
          elevation: 0,
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
                  Text("Value : $_value, ${_value.length}"),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        String? input =
                            await _showInputDialog(controller, "Capturenya");
                        if (input != null) {
                          List<int> list = utf8.encode("capture!$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(bytes, "Success Capture!", device);
                        }
                      } catch (e) {
                        Snackbar.show(ScreenSnackbar.capturesettings,
                            "Error Capture! : $e",
                            success: false);
                      }
                    },
                    child: const Text("Capture!"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        String? input =
                            await _showInputDialog(controller, "Coba Transmit");
                        if (input != null) {
                          List<int> list =
                              utf8.encode("capture_transmit!$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(bytes, "Success Stop!", device);
                          isCaptureTransmit = true;
                        }
                      } catch (e) {
                        Snackbar.show(
                            ScreenSnackbar.capturesettings, "Error Stop! : $e",
                            success: false);
                      }
                    },
                    child: const Text("Capture Transmit!"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ===== for connection ===================

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

  Future onConnectPressed() async {
    try {
      await device.connectAndUpdateStream();
      // initDiscoverServices();
      Snackbar.show(ScreenSnackbar.transmitsettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.transmitsettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.transmitsettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.transmitsettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.transmitsettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.transmitsettings,
          prettyException("Disconnect Error:", e),
          success: false);
      log(e.toString());
    }
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
