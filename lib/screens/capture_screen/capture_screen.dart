import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_capture.dart';
import 'package:ble_test/ble-v2/model/image_meta_data_model/image_meta_data_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  ImageMetaDataModel? _imageMetaData;

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

  Future<String> saveImage(Uint8List imageBytes, String fileName) async {
    try {
      // Dapatkan direktori penyimpanan lokal
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';

      // Tulis byte ke file
      File file = File(path);
      await file.writeAsBytes(imageBytes);

      Snackbar.show(ScreenSnackbar.device, "Berkas disimapan di: $path",
          success: true);

      return path;
    } catch (e) {
      Snackbar.show(ScreenSnackbar.device, "Gagal menyimpan gambar : $e",
          success: false);
      return "";
    }
  }

  @override
  void dispose() {
    imageBytes.clear();
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  void _showMetaDataImageDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Meta Data"),
            children: [
              SimpleDialogOption(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ID : ${ConvertV2().arrayUint8ToStringHexAddress((_imageMetaData!.id ?? []))}",
                    ),
                    const SizedBox(height: 3),
                    Text("ID Pelanggan : ${_imageMetaData!.custom}"),
                    const SizedBox(height: 3),
                    Text("Model Meter : ${_imageMetaData!.meterModel}"),
                    const SizedBox(height: 3),
                    Text("Nomor Seri Meter : ${_imageMetaData!.meterSN}"),
                    const SizedBox(height: 3),
                    Text("Segel Meter : ${_imageMetaData!.meterSeal}"),
                    const SizedBox(height: 3),
                    Text(
                        "Tanggal Diambil : ${(_imageMetaData!.getDateTimeTakenString())}"),
                    const SizedBox(height: 3),
                    Text(
                      "Waktu UTC : ${ConvertV2().uint8ToUtcString((_imageMetaData!.timeUTC ?? 0))}",
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Tegangan Baterai 1 : ${(_imageMetaData!.voltageBattery1 ?? 0).toStringAsFixed(2)} V",
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Tegangan Baterai 2 : ${(_imageMetaData!.voltageBattery2 ?? 0).toStringAsFixed(2)} V",
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Suhu : ${(_imageMetaData!.temperature ?? 0).toStringAsFixed(2)}°C",
                    ),
                  ],
                ),
                onPressed: () {},
              )
            ],
          );
        });
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
        // return true;
        if (!isCapturing) {
          return true;
        } else {
          return false;
        }
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        imageBytes.isEmpty
                            ? const SizedBox()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade800,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        15), // Set the corner radius
                                  ),
                                ),
                                onPressed: () async {
                                  String datetimenow =
                                      DateTime.now().toString();
                                  String fileName = "TOPPI_$datetimenow.png";
                                  String hasil =
                                      await saveImage(imageBytes, fileName);
                                  if (hasil != "") {
                                    Snackbar.show(
                                      ScreenSnackbar.capture,
                                      "Gambar tersimpan di $hasil",
                                      success: true,
                                    );
                                  } else {
                                    Snackbar.show(
                                      ScreenSnackbar.capture,
                                      "Gagal menyimpan gambar",
                                      success: false,
                                    );
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.arrow_down_doc,
                                  size: 35,
                                ),
                              ),
                        const SizedBox(
                          width: 10,
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
                            _imageMetaData = null;
                            imageBytes = Uint8List(0);
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
                                  Map<String, dynamic> dataParse =
                                      ImageMetaDataModelParse.parse(data.data!);

                                  imageBytes = dataParse["img"];
                                  _imageMetaData = dataParse['metaData'];
                                  setState(() {});
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
                        const SizedBox(
                          width: 10,
                        ),
                        _imageMetaData == null
                            ? const SizedBox()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigoAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        15), // Set the corner radius
                                  ),
                                ),
                                onPressed: () {
                                  _showMetaDataImageDialog(context);
                                },
                                child: const Icon(
                                  Icons.info_outline,
                                  size: 35,
                                ),
                              )
                      ],
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
