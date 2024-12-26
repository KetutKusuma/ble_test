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
  List<List<dynamic>> captureResultTransmitTemp = [];
  List<int> totalChunkData = [];
  bool isCaptureDone = false;
  bool isCaptureCommandDone = false;

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
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isCaptureCommandDone = false;
    isCaptureScreen = false;
    captureResult.clear();
    captureResultTransmitTemp.clear();
    totalChunkData.clear();
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
                // log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;

                // log("VALUE : $_value, ${_value.length}");

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
                  // log("captureResult : $captureResult");
                  isCaptureCommandDone = true;
                }

                // this is for capture_transmit! response
                if (_value.length >= 500) {
                  // pertama ubah dulu datanya atau convert
                  // simpan ke dalam list chunk jika
                  // crc32 == hashCrc32(data) jika tidak maka akan diberikan error
                  // lakukan juga pengecekan number of chunk jika ada yang kosong atau kelewat
                  try {
                    // [0] -> chunck sequence number
                    // [1] -> length of chunk
                    // [2] -> chunk data
                    // [3] -> crc32
                    List<dynamic> captureTransmitResult =
                        CaptureConverter.convertSquenceCapture(_value, 500);

                    if (captureTransmitResult.length == 2) {
                      // lakukan perbaikan
                      captureResultTransmitTemp.add(captureTransmitResult);
                      log("got error when capture transmit result number : ${captureTransmitResult[0]} error : ${captureTransmitResult[1]}");
                      List<int> list = utf8.encode(
                          "capture_transmit!${captureTransmitResult[0]}");
                      Uint8List bytes = Uint8List.fromList(list);
                      BLEUtils.funcWrite(
                          bytes,
                          "Success Capture Transmit fixing ${captureTransmitResult[0]}",
                          device);
                    } else {
                      // tambah pada captureReusltTransmit Temp
                      // check dulu numbersnya sama atau tidak dengan length captureResultTransmitTemp
                      // jika iya maka tambah
                      // jika tidak maka gantikan dengan nomer tersebut
                      log("sudah sampai ygy");
                      log("adek : ${captureResultTransmitTemp.length} == ${captureTransmitResult[0]}");
                      if (captureResultTransmitTemp.length !=
                          captureTransmitResult[0]) {
                        // log("sampai transmit temp tidak sama dengan capture[0] ${captureResultTransmitTemp.length} / numbers : ${captureTransmitResult[0]}");
                        // jika tidak sama maka gantikan
                        // remove
                        captureResultTransmitTemp
                            .removeAt(captureTransmitResult[0]);
                        // insert new
                        captureResultTransmitTemp.insert(
                            captureTransmitResult[0], captureTransmitResult);
                        try {
                          log("helper start ...");
                          // check jika length temp sama dengan total chunck
                          if (captureResultTransmitTemp.length !=
                              captureResult[2]) {
                            // check jika squence number sama dengan urutan pada temp
                            for (int i = 0;
                                i < captureResultTransmitTemp.length - 1;
                                i++) {
                              log("logst 1 ${captureResultTransmitTemp[i][0]} == $i");
                              if (captureResultTransmitTemp[i][0] != i) {
                                // jika tidak sama maka akan disort ulang
                                captureResultTransmitTemp.sort(
                                  (a, b) => a[0].compareTo(
                                    b[0],
                                  ),
                                );
                                break;
                              }
                              log("logst $i == ${captureResultTransmitTemp.length - 1}");
                              if (i == captureResultTransmitTemp.length - 1) {
                                // berarti ini sudah lolos dan lanjut ditambahkan ke dalam total chunk
                                // mungkin dilakukan pengecekan crc32
                                totalChunkData = captureResultTransmitTemp
                                    .expand((outer) => outer.first)
                                    .toList() as List<int>;
                                log("total chunk : $totalChunkData");
                                if (mounted) {
                                  setState(() {
                                    isCaptureDone = true;
                                  });
                                }
                              } else {
                                log("BAHWA ERROR DISINI KETIKA MELAKUKAN PERBAIKAN SAYA PUSING");
                              }
                            }
                          }
                        } catch (e) {
                          log("error when helper last value : $e");
                        }
                      } else {
                        log("sampai add transmit temp");
                        // jika sama maka tambah saja
                        captureResultTransmitTemp.add(captureTransmitResult);

                        // try {
                        //   log("helper start ...");
                        //   // check jika length temp sama dengan total chunck
                        //   if (captureResultTransmitTemp.length !=
                        //       captureResult[2]) {
                        //     // check jika squence number sama dengan urutan pada temp
                        //     for (int i = 0;
                        //         i < captureResultTransmitTemp.length - 1;
                        //         i++) {
                        //       log("logss 1 ${captureResultTransmitTemp[i][0]} == $i");
                        //       if (captureResultTransmitTemp[i][0] != i) {
                        //         // jika tidak sama maka akan disort ulang
                        //         captureResultTransmitTemp.sort(
                        //           (a, b) => a[0].compareTo(
                        //             b[0],
                        //           ),
                        //         );
                        //         break;
                        //       }
                        //       log("logss $i == ${captureResultTransmitTemp.length - 1}");
                        //       if (i == captureResultTransmitTemp.length - 1) {
                        //         // berarti ini sudah lolos dan lanjut ditambahkan ke dalam total chunk
                        //         // mungkin dilakukan pengecekan crc32
                        //         totalChunkData = captureResultTransmitTemp
                        //             .expand((outer) => outer.first)
                        //             .toList() as List<int>;
                        //         log("total chunk : $totalChunkData");
                        //         if (mounted) {
                        //           setState(() {
                        //             isCaptureDone = true;
                        //           });
                        //         }
                        //       } else {
                        //         log("2 BAHWA ERROR DISINI KETIKA MELAKUKAN PERBAIKAN SAYA PUSING");
                        //       }
                        //     }
                        //   }
                        // } catch (e) {
                        //   log("error when helper last value : $e");
                        // }
                      }
                    }

                    // log("captureTransmitResult : $captureTransmitResult");
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

  void helperLastValue() {
    try {
      log("helper start ...");
      // check jika length temp sama dengan total chunck
      if (captureResultTransmitTemp.length != captureResult[2]) {
        // check jika squence number sama dengan urutan pada temp
        for (int i = 0; i < captureResultTransmitTemp.length - 1; i++) {
          log("logss 1 ${captureResultTransmitTemp[i][0]} == $i");
          if (captureResultTransmitTemp[i][0] != i) {
            // jika tidak sama maka akan disort ulang
            captureResultTransmitTemp.sort(
              (a, b) => a[0].compareTo(
                b[0],
              ),
            );
            break;
          }
          log("logss $i == ${captureResultTransmitTemp.length - 1}");
          if (i == captureResultTransmitTemp.length - 1) {
            // berarti ini sudah lolos dan lanjut ditambahkan ke dalam total chunk
            // mungkin dilakukan pengecekan crc32
            totalChunkData = captureResultTransmitTemp
                .expand((outer) => outer.first)
                .toList() as List<int>;
            log("total chunk : $totalChunkData");
            if (mounted) {
              setState(() {
                isCaptureDone = true;
              });
            }
          } else {
            log("BAHWA ERROR DISINI KETIKA MELAKUKAN PERBAIKAN SAYA PUSING");
          }
        }
      }
    } catch (e) {
      log("error when helper last value : $e");
    }
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
                        totalChunkData.clear();
                        captureResultTransmitTemp.clear();
                        List<int> list = utf8.encode("capture!500");
                        Uint8List bytes = Uint8List.fromList(list);
                        BLEUtils.funcWrite(bytes, "Success Capture!", device);

                        await Future.delayed(const Duration(milliseconds: 800));
                        List<int> listT = utf8.encode("capture_transmit!");
                        Uint8List bytesT = Uint8List.fromList(listT);
                        BLEUtils.funcWrite(
                            bytesT, "Success Capture Transmit!", device);
                      } catch (e) {
                        Snackbar.show(
                            ScreenSnackbar.capture, "Error Capture! : $e",
                            success: false);
                      }
                    },
                    child: const Text("Capture"),
                  ),
                  // ElevatedButton(
                  //   onPressed: () async {
                  //     try {
                  //       // String? input =
                  //       //     await _showInputDialog(controller, "Capturenya");
                  //       // if (input != null) {
                  //       //   List<int> list = utf8.encode("capture!$input");
                  //       //   Uint8List bytes = Uint8List.fromList(list);
                  //       //   BLEUtils.funcWrite(bytes, "Success Capture!", device);
                  //       // }
                  //       List<int> list = utf8.encode("capture!500");
                  //       Uint8List bytes = Uint8List.fromList(list);
                  //       BLEUtils.funcWrite(bytes, "Success Capture!", device);
                  //     } catch (e) {
                  //       Snackbar.show(ScreenSnackbar.capturesettings,
                  //           "Error Capture! : $e",
                  //           success: false);
                  //     }
                  //   },
                  //   child: const Text("Capture!"),
                  // ),

                  // //! THIS IS FOR CAPTURE TRANSMIT TEST
                  // //! AFTER THIS WORK I WANT TO MERGE THE CAPTURE AND CAPTURE TRANSMIT
                  // //! TO CAPTURE JUST CAPTURE
                  // ElevatedButton(
                  //   onPressed: () async {
                  //     try {
                  //       // String? input =
                  //       //     await _showInputDialog(controller, "Coba Transmit");
                  //       // if (input != null) {
                  //       //   List<int> list =
                  //       //       utf8.encode("capture_transmit!$input");
                  //       //   Uint8List bytes = Uint8List.fromList(list);
                  //       //   BLEUtils.funcWrite(bytes, "Success Stop!", device);
                  //       //   isCaptureTransmit = true;
                  //       // }
                  //       totalChunkData.clear();
                  //       captureResultTransmitTemp.clear();
                  //       // captureResult.clear();
                  //       List<int> list = utf8.encode("capture_transmit!");
                  //       Uint8List bytes = Uint8List.fromList(list);
                  //       BLEUtils.funcWrite(
                  //           bytes, "Success Capture Transmit!", device);

                  //       // isCaptureTransmit = true;
                  //     } catch (e) {
                  //       Snackbar.show(
                  //           ScreenSnackbar.capturesettings, "Error Stop! : $e",
                  //           success: false);
                  //     }
                  //   },
                  //   child: const Text("Capture Transmit!"),
                  // ),
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