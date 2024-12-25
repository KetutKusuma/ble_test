import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/converter/capture/capture.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../utils/crc32.dart';

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

  List<dynamic> captureResult = [];
  List<List<dynamic>> captureResultTransmit = [];
  List<int> totalChunkData = [];
  bool isCaptureDone = false;

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
    isCaptureScreen = false;
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    super.dispose();
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
                // if (isCaptureTransmit) {}
                // this is for capture! response
                if (_value.length == 39) {
                  // pertama ubah dulu datanya atau convert
                  // lalu simpan
                  // nanti jika sudah semua datanya ada cek dengan
                  // cek panjangnya dapat berapa dari capture! == panjang datanya berapa
                  // cek jika crc32 == data dihash crc32 sama atau tidak?
                  // lakukan juga pengecekan number of chunk jika ada yang kosong atau kelewat
                  // maka akan dicari dengan menggunakan capture_transmit?<number of missing>
                  // [0] -> status
                  // [1] -> message
                  // [2] -> total chunk
                  // [3] -> crc32
                  captureResult =
                      CaptureConverter.convertManifestCapture(_value);
                  log("captureResult : $captureResult");
                }

                // this is for capture_transmit! response
                if (_value.length >= 500) {
                  // pertama ubah dulu datanya atau convert
                  // simpan ke dalam list chunk jika
                  // crc32 == hashCrc32(data) jika tidak maka akan diberikan error
                  // lakukan juga pengecekan number of chunk jika ada yang kosong atau kelewat
                  try {
                    List<dynamic> captureTransmitResult =
                        CaptureConverter.convertSquenceCapture(_value, 500);
                    // [0] -> chunck sequence number
                    // [1] -> length of chunk
                    // [2] -> chunk data
                    // [3] -> crc32
                    captureResultTransmit.add(captureTransmitResult);
                    log("type of transmit[2] : ${captureTransmitResult[2].runtimeType}");
                    totalChunkData = totalChunkData + captureTransmitResult[2];
                    // checking total chunck == captureResultChnk length
                    log("capture result chunk : ${captureResult[2]} == ${captureResultTransmit.length}");
                    if (captureResult[2] == captureResultTransmit.length) {
                      log("MATCH TOTAL CHUNK");
                      for (int i = 0; i < captureResultTransmit.length; i++) {
                        List<dynamic> element = captureResultTransmit[i];

                        /// checking number of chunck
                        log("number of chunck : ${element[0]}");
                        // checking if the chunck just has length 2 that mean the chunck sequence is error
                        log("length of element : ${element.length}");
                      }
                      log("LENGTH OF CHUNCK DATA : ${totalChunkData.length}");
                      log("CHUNCK DATA : $totalChunkData");
                      // checking hashcrc32(totalchunck) == crc32 of captureResult
                      int crc32TotalChunck = CRC32.compute(totalChunkData);
                      log("CRC32 total chunck : $crc32TotalChunck");
                      log("MATCH CRC32 total chunck : ${crc32TotalChunck == captureResult[3]} | hash : $crc32TotalChunck == crc32 got : ${captureResult[3]}");
                      isCaptureDone = true;
                    }
                    log("captureTransmitResult : $captureTransmitResult");
                  } catch (e) {
                    log("error when get squance chunck : $e");
                  }
                }

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
                        // String? input =
                        //     await _showInputDialog(controller, "Capturenya");
                        // if (input != null) {
                        //   List<int> list = utf8.encode("capture!$input");
                        //   Uint8List bytes = Uint8List.fromList(list);
                        //   BLEUtils.funcWrite(bytes, "Success Capture!", device);
                        // }
                        List<int> list = utf8.encode("capture!500");
                        Uint8List bytes = Uint8List.fromList(list);
                        BLEUtils.funcWrite(bytes, "Success Capture!", device);
                      } catch (e) {
                        Snackbar.show(ScreenSnackbar.capturesettings,
                            "Error Capture! : $e",
                            success: false);
                      }
                    },
                    child: const Text("Capture!"),
                  ),

                  //! THIS IS FOR CAPTURE TRANSMIT TEST
                  //! AFTER THIS WORK I WANT TO MERGE THE CAPTURE AND CAPTURE TRANSMIT
                  //! TO CAPTURE JUST CAPTURE
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // String? input =
                        //     await _showInputDialog(controller, "Coba Transmit");
                        // if (input != null) {
                        //   List<int> list =
                        //       utf8.encode("capture_transmit!$input");
                        //   Uint8List bytes = Uint8List.fromList(list);
                        //   BLEUtils.funcWrite(bytes, "Success Stop!", device);
                        //   isCaptureTransmit = true;
                        // }
                        totalChunkData.clear();
                        captureResultTransmit.clear();
                        // captureResult.clear();
                        List<int> list = utf8.encode("capture_transmit!");
                        Uint8List bytes = Uint8List.fromList(list);
                        BLEUtils.funcWrite(
                            bytes, "Success Capture Transmit!", device);

                        // isCaptureTransmit = true;
                      } catch (e) {
                        Snackbar.show(
                            ScreenSnackbar.capturesettings, "Error Stop! : $e",
                            success: false);
                      }
                    },
                    child: const Text("Capture Transmit!"),
                  ),
                  !isCaptureDone
                      ? const SizedBox()
                      : Image.memory(
                          Uint8List.fromList(totalChunkData),
                        )
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
