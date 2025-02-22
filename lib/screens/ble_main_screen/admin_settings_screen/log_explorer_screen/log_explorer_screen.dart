import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_image_file_capture.dart';
import 'package:ble_test/ble-v2/download_utils/download_utils.dart';
import 'package:ble_test/ble-v2/model/sub_model/explorer/log_explorer.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

class LogExplorerScreen extends StatefulWidget {
  final BluetoothDevice device;

  const LogExplorerScreen({super.key, required this.device});

  @override
  State<LogExplorerScreen> createState() => _LogExplorerScreenState();
}

class _LogExplorerScreenState extends State<LogExplorerScreen> {
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  late SimpleFontelicoProgressDialog _progressDialog;
  CommandImageFile commandImageFile = CommandImageFile();
  List<LogExplorerModel> listLogExplorer = [];

  @override
  void initState() {
    // TODO: implement initState
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

            Snackbar.show(
              ScreenSnackbar.adminsettings,
              "Perangkat Tidak Terhubung",
              success: false,
            );
          }
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressDialog = SimpleFontelicoProgressDialog(
          context: context, barrierDimisable: true);
      _showLoading();
    });
    initGetLogExplorer();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Harap Tunggu...",
    );
  }

  initGetLogExplorer() async {
    try {
      BLEResponse<ToppiExplorerModel> data =
          await commandImageFile.getLogExplorer(bleProvider, 255);
      if (!data.status) {
        Snackbar.show(
          ScreenSnackbar.logexplorerscreen,
          data.message,
          success: false,
        );
        return;
      }

      ToppiFileModel toppiFile = ToppiFileModel(
        fileSize: data.data!.fileSize,
        totalChunck: data.data!.totalChunck,
        crc32: data.data!.crc32,
      );

      BLEResponse<List<int>> dataBuffer =
          await commandImageFile.dataBufferTransmit(
        bleProvider,
        toppiFile,
        255,
      );

      if (!dataBuffer.status) {
        Snackbar.show(
          ScreenSnackbar.logexplorerscreen,
          dataBuffer.message,
          success: false,
        );
        return;
      }

      List<int> buffer = dataBuffer.data ?? [];

      // build kalau di golangnya
      int fileNameLen = 14;
      int payloadLen = fileNameLen + 4;
      for (int i = 0; i < data.data!.totalFile; i++) {
        int startIndex = i * payloadLen;
        listLogExplorer.add(LogExplorerModel(
            filename: buffer.sublist(startIndex, startIndex + fileNameLen),
            fileSize:
                ConvertV2().bufferToUint32(buffer, startIndex + fileNameLen)));
      }

      setState(() {});

      _progressDialog.hide();

      // Snackbar.show(
      //   ScreenSnackbar.logexplorerscreen,
      //   "Sukses dapat daftar catatan",
      //   success: true,
      // );
    } catch (e) {
      Snackbar.show(
        ScreenSnackbar.logexplorerscreen,
        "Error layar daftar catatan : $e",
        success: false,
      );
    }
  }

  Future getBufferDataLogFile(List<int> fileName, String fileNameString) async {
    try {
      _progressDialog.show(
        message: "Tunggu sedang mengambil data catatan ...",
        width: MediaQuery.of(context).size.width / 2,
        textStyle: const TextStyle(
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
      );
      BLEResponse<ToppiFileModel> data =
          await commandImageFile.logFilePrepareTransmit(
        bleProvider,
        fileName,
        255,
      );
      if (!data.status) {
        _progressDialog.hide();

        Snackbar.show(ScreenSnackbar.logexplorerscreen, data.message,
            success: false);
        return;
      }
      if (data.data == null) {
        _progressDialog.hide();

        Snackbar.show(
          ScreenSnackbar.logexplorerscreen,
          "Data berkas catatan kosong",
          success: false,
        );
        return;
      }

      BLEResponse<List<int>> dataBuffer =
          await commandImageFile.dataBufferTransmit(
        bleProvider,
        data.data!,
        255,
      );

      if (!dataBuffer.status) {
        _progressDialog.hide();

        Snackbar.show(
          ScreenSnackbar.logexplorerscreen,
          dataBuffer.message,
          success: false,
        );

        return;
      }

      Uint8List dataGzip =
          await decompressGzip(Uint8List.fromList(dataBuffer.data ?? []));

      _progressDialog.hide();
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            // title: Text("Catatan $fileNameString"),
            child: Padding(
              padding: const EdgeInsets.only(left: 5, right: 5, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Catatan $fileNameString",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: SingleChildScrollView(
                      child: Text(
                        utf8.decode(dataGzip, allowMalformed: true),
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 5, right: 5),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          var status = await Permission.storage.request();
                          if (!status.isGranted) {
                            Snackbar.show(
                              ScreenSnackbar.logexplorerscreen,
                              "Izin penyimpanan ditolak",
                              success: false,
                            );
                            return;
                          }
                          DateTime dateTime = DateTime.now();
                          String datetimenow =
                              DateFormat('yyyy-MM-dd_HH#mm').format(dateTime);
                          String fileName = "log_$datetimenow.txt";
                          if (mounted) {
                            Navigator.pop(context);
                            await DownloadUtils.saveToDownload(
                              context,
                              ScreenSnackbar.logexplorerscreen,
                              dataGzip,
                              fileName,
                            );
                          }
                        } catch (e) {
                          log("error : $e");
                          Snackbar.show(
                            ScreenSnackbar.logexplorerscreen,
                            "Gagal dapat menyimpan gambar : $e",
                            success: false,
                          );
                        }
                      },
                      child: const Text("Simpan"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _progressDialog.hide();

      Snackbar.show(
        ScreenSnackbar.logexplorerscreen,
        "Error dapat layar daftar catatan : $e",
        success: false,
      );
      return;
    }
  }

  Future<Uint8List> decompressGzip(Uint8List data) async {
    try {
      // Create a ByteStream from the input data
      final reader = ByteData.sublistView(data);
      final inflater = ZLibDecoder();

      // Decompress the data
      return Uint8List.fromList(inflater.convert(data));
    } catch (e) {
      // Return an error message as bytes
      return Uint8List.fromList(utf8.encode("failed to decompress data"));
    }
  }

  Future<void> onRefresh() async {
    setState(() {
      listLogExplorer.clear();
      initGetLogExplorer();
    });
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyLogExplorerScreen,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            "Daftar Catatan",
          ),
        ),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return GestureDetector(
                      onTap: () {
                        getBufferDataLogFile(listLogExplorer[index].filename,
                            listLogExplorer[index].getFilenameString());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin:
                            const EdgeInsets.only(top: 8, left: 5, right: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.radio_button_checked,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listLogExplorer[index].getFilenameString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 15,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              listLogExplorer[index]
                                                  .getDateString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.insert_drive_file_outlined,
                                            size: 15,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              listLogExplorer[index]
                                                  .getFileSizeString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: listLogExplorer.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 15,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
