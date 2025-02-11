import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_capture.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CaptureScreen extends StatefulWidget {
  final BluetoothDevice device;

  const CaptureScreen({super.key, required this.device});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late BLEProvider bleProvider;
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  Timer? debounceTimer;

  // v2
  final _commandCapture = CommandCapture();
  bool isCapturing = false;
  bool isCaptureDone = false;
  Uint8List imageBytes = Uint8List(0);

  @override
  void initState() {
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        _connectionState = state;
        if (_connectionState == BluetoothConnectionState.disconnected) {
          if (mounted) {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          }
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  void _showZoomableImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(builder: (context, constraints) {
            return InteractiveViewer(
              scaleFactor: 400,
              clipBehavior: Clip.none,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 1,
              maxScale: 3.0,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // log("isCapture = $isCaptureDone");
    return WillPopScope(
      onWillPop: () async {
        return true;
        // if (isCaptureDone) {
        //   return true;
        // } else {
        //   return false;
        // }
      },
      child: ScaffoldMessenger(
        key: Snackbar.snackBarCapture,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Pengambilan Gambar"),
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      padding: const EdgeInsets.all(5),
                      width: MediaQuery.of(context).size.width,
                      height: 290,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: !isCapturing
                          ? (isCaptureDone
                              ? (GestureDetector(
                                  onTap: () {
                                    _showZoomableImageDialog(
                                      context,
                                      Uint8List.fromList(imageBytes),
                                    );
                                  },
                                  child: FittedBox(
                                    child: Center(
                                      child: Image.memory(
                                        Uint8List.fromList(imageBytes),
                                        fit: BoxFit.fill,
                                        scale: 1,
                                      ),
                                    ),
                                  ),
                                ))
                              : const Icon(
                                  CupertinoIcons.photo,
                                  color: Colors.black45,
                                  size: 40,
                                ))
                          : (isCapturing && !isCaptureDone)
                              ? const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.photo,
                                  color: Colors.black45,
                                  size: 40,
                                ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              15), // Set the corner radius
                        ),
                      ),
                      onPressed: () async {
                        isCaptureDone = false;
                        isCapturing = true;
                        setState(() {});
                        int bytePerChunk = 255;
                        try {
                          BLEResponse<TestCaptureModel> bleResponse =
                              await _commandCapture.testCapture(
                                  bleProvider, bytePerChunk);
                          log("test capture : $bleResponse");

                          if (bleResponse.data == null) {
                            isCapturing = false;
                            setState(() {});
                            Snackbar.show(ScreenSnackbar.capture,
                                "Error Pengambilan gambar, data kosong",
                                success: false);
                          }
                          if (!bleResponse.status) {
                            isCapturing = false;
                            setState(() {});
                            Snackbar.show(
                                ScreenSnackbar.capture, bleResponse.message,
                                success: false);
                          } else {
                            BLEResponse<List<int>> data =
                                await _commandCapture.dataBufferTransmit(
                              bleProvider,
                              bleResponse.data!,
                              bytePerChunk,
                            );

                            log("data buffer transmit : $data");

                            if (!data.status) {
                              isCapturing = false;
                              setState(() {});
                              Snackbar.show(
                                  ScreenSnackbar.capture, data.message,
                                  success: false);
                            } else {
                              isCaptureDone = true;
                              isCapturing = false;
                              setState(() {
                                imageBytes =
                                    Uint8List.fromList(data.data ?? [0]);
                              });
                            }
                          }
                        } catch (e) {
                          Snackbar.show(
                              ScreenSnackbar.capture, "Error Capture! : $e",
                              success: false);
                        }
                      },
                      child: const Icon(
                        Icons.camera,
                        size: 35,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
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
