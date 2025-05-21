import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_image_file_capture.dart';
import 'package:ble_test/ble-v2/model/image_meta_data_model/image_meta_data_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/explorer/image_explorer.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/ble-v2/server/server.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/rtc.dart';
import 'package:ble_test/config/config.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

import '../../../../ble-v2/download_utils/download_utils.dart';
import 'package:http/http.dart' as http;

class ListImageExplorerScreen extends StatefulWidget {
  final int filter;
  final String title;
  final BluetoothDevice device;

  const ListImageExplorerScreen(
      {super.key,
      required this.filter,
      required this.title,
      required this.device});

  @override
  State<ListImageExplorerScreen> createState() =>
      _ListImageExplorerScreenState();
}

class _ListImageExplorerScreenState extends State<ListImageExplorerScreen> {
  get title => widget.title;
  get filter => widget.filter;
  get device => widget.device;
  late BLEProvider bleProvider;
  late ConfigProvider configProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  late SimpleFontelicoProgressDialog _progressDialog;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final _commandImageFile = CommandImageFile();
  List<ImageExplorerModel> listImageExplorer = [];

  @override
  void initState() {
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    configProvider = Provider.of<ConfigProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressDialog = SimpleFontelicoProgressDialog(
          context: context, barrierDimisable: true);
      _showLoading();
    });
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        _connectionState = state;
        if (_connectionState == BluetoothConnectionState.disconnected) {
          Navigator.popUntil(
            context,
            (route) => route.isFirst,
          );
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    initGetImageExplorer();
  }

  @override
  void dispose() {
    super.dispose();
    _connectionStateSubscription.cancel();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Harap Tunggu...",
    );
  }

  Future initGetImageExplorer() async {
    int bytePerChunk = 255;
    try {
      BLEResponse<ToppiExplorerModel> data = await _commandImageFile
          .getImageFileExplorer(bleProvider, filter, bytePerChunk);

      if (!data.status) {
        _progressDialog.hide();

        Snackbar.show(
          ScreenSnackbar.imageexplorerscreen,
          data.message,
          success: false,
        );
        return;
      }

      ToppiFileModel toppiFileModel = ToppiFileModel(
        fileSize: data.data!.fileSize,
        totalChunck: data.data!.totalChunck,
        crc32: data.data!.crc32,
      );

      BLEResponse<List<int>> dataBuffer =
          await _commandImageFile.dataBufferTransmit(
        bleProvider,
        toppiFileModel,
        bytePerChunk,
      );

      if (!dataBuffer.status) {
        _progressDialog.hide();

        Snackbar.show(
          ScreenSnackbar.imageexplorerscreen,
          dataBuffer.message,
          success: false,
        );
        return;
      }

      List<int> buffer = dataBuffer.data ?? [];

      if (buffer.isEmpty) {
        _progressDialog.hide();
        Snackbar.show(
          ScreenSnackbar.imageexplorerscreen,
          "Tidak ada data",
          success: false,
        );
        return;
      }

      // build kalau di golangnya
      int fileNameLen = 19;
      int payloadLen = fileNameLen + 1 + 4;
      for (int i = 0; i < data.data!.totalFile; i++) {
        int startIndex = i * payloadLen;

        List<int> fileName =
            buffer.sublist(startIndex, startIndex + fileNameLen);
        List<int> bufferSeconds = ConvertV2().stringHexToArrayUint8(
            String.fromCharCodes(fileName.sublist(11, 19)), 4);

        DateTime dateTime = RTC.getTimeFromSeconds(
            ConvertV2().bufferToUint32BigEndian(bufferSeconds, 0));

        int dirIndex = buffer.sublist(startIndex + fileNameLen)[0];
        if (dirIndex < 0 || dirIndex > 1) {
          _progressDialog.hide();
          throw Exception("Direktori tidak valid : $dirIndex");
        }

        listImageExplorer.add(
          ImageExplorerModel(
            dateTime: dateTime,
            filename: fileName,
            dirIndex: dirIndex,
            fileSize: ConvertV2()
                .bufferToUint32(buffer, startIndex + fileNameLen + 1),
          ),
        );

        _progressDialog.hide();
        listImageExplorer.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        setState(() {});
      }
    } catch (e) {
      _progressDialog.hide();
      Snackbar.show(
        ScreenSnackbar.imageexplorerscreen,
        "Error layar daftar gambar : $e",
        success: false,
      );
    }
  }

  Future getBufferDataImageFile(
      List<ImageExplorerModel> imageExplorer, int index) async {
    try {
      _progressDialog.show(
        message: "Tunggu sedang mengambil data gambar ...",
        width: MediaQuery.of(context).size.width / 2,
        textStyle: const TextStyle(
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
      );

      BLEResponse<ToppiFileModel> data =
          await _commandImageFile.imageFilePrepareTransmit(
        bleProvider,
        imageExplorer[index].dirIndex,
        imageExplorer[index].filename,
        255,
      );

      if (!data.status) {
        _progressDialog.hide();
        Snackbar.show(
          ScreenSnackbar.imageexplorerscreen,
          data.message,
          success: false,
        );
        return;
      }
      if (data.data == null) {
        _progressDialog.hide();
        Snackbar.show(
          ScreenSnackbar.imageexplorerscreen,
          "Data berkas gambar kosong",
          success: false,
        );
        return;
      }

      BLEResponse<List<int>> dataBuffer =
          await _commandImageFile.dataBufferTransmit(
        bleProvider,
        data.data!,
        255,
      );

      if (!dataBuffer.status) {
        _progressDialog.hide();
        Snackbar.show(
          ScreenSnackbar.imageexplorerscreen,
          dataBuffer.message,
          success: false,
        );
        return;
      }

      // parse
      Map<String, dynamic> dataParse =
          ImageMetaDataModelParse.parse(dataBuffer.data!);

      ImageMetaDataModel imageMetaData = dataParse["metaData"];

      List<Widget> buildMetadataTextsV2(
        ImageMetaDataModel imageMetaData,
      ) {
        final List<Widget> widgets = [];

        void addText(String text) {
          widgets.add(Text(text));
        }

        addText("Firmware : ${imageMetaData.firmware}");
        addText("Version : ${imageMetaData.version}");
        addText(
            "ID : ${ConvertV2().arrayUint8ToStringHexAddress((imageMetaData.id ?? []))}");
        addText("ID Pelanggan : ${imageMetaData.custom}");
        addText("Model Meter : ${imageMetaData.meterModel}");
        addText("Nomor Seri Meter : ${imageMetaData.meterSN}");
        addText("Segel Meter : ${imageMetaData.meterSeal}");
        addText("Tanggal Diambil : ${imageMetaData.getDateTimeTakenString()}");
        addText(
            "Waktu UTC : ${ConvertV2().uint8ToUtcString((imageMetaData.timeUTC ?? 0))}");
        addText(
            "Tegangan Baterai 1 : ${(imageMetaData.voltageBattery1 ?? 0).toStringAsFixed(2)} V");
        addText(
            "Tegangan Baterai 2 : ${(imageMetaData.voltageBattery2 ?? 0).toStringAsFixed(2)} V");
        addText("Rotasi Kamera : ${imageMetaData.adjustmentRotation}");
        addText(
            "Temperatur : ${(imageMetaData.temperature ?? 0).toStringAsFixed(2)}°C");
        addText(
            "Ukuran Gambar : ${listImageExplorer[index].getFileSizeString()}");

        // Sisipkan SizedBox(height: 3) antar elemen kecuali terakhir
        return [
          for (int i = 0; i < widgets.length; i++) ...[
            widgets[i],
            if (i != widgets.length - 1) const SizedBox(height: 3),
          ]
        ];
      }

      List<Widget> buildMetadataTextsV3(ImageMetaDataModel imageMetaData) {
        final List<Widget> widgets = [];

        void addText(String text) {
          widgets.add(Text(text));
        }

        addText(
            "Firmware & Version : ${imageMetaData.firmware} v${imageMetaData.version}");
        addText(
            "ID : ${ConvertV2().arrayUint8ToStringHexAddress((imageMetaData.id ?? []))}");
        addText("ID Pelanggan : ${imageMetaData.customerID}");
        addText("Tanggal Diambil : ${imageMetaData.getDateTimeTakenString()}");
        addText(
            "Waktu UTC : ${ConvertV2().uint8ToUtcString((imageMetaData.timeUTC ?? 0))}");
        addText(
            "Temperatur : ${(imageMetaData.temperature ?? 0).toStringAsFixed(2)}°C");
        addText("Role : ${imageMetaData.getRoleString()}");
        addText(
            "Tegangan Baterai 1 : ${(imageMetaData.voltageBattery1 ?? 0).toStringAsFixed(2)} V");
        addText(
            "Tegangan Baterai 2 : ${(imageMetaData.voltageBattery2 ?? 0).toStringAsFixed(2)} V");
        addText("Rotasi Kamera : ${imageMetaData.adjustmentRotation}");
        addText("Model Meter : ${imageMetaData.meterModel}");
        addText("Nomor Seri Meter : ${imageMetaData.meterSN}");
        addText("Segel Meter : ${imageMetaData.meterSeal}");
        addText(
            "Angka Bulat/Desimal : ${imageMetaData.numberDigit}/${imageMetaData.numberDecimal}");
        addText("Kustom : ${imageMetaData.custom}");
        addText(
            "Ukuran Gambar : ${listImageExplorer[index].getFileSizeString()}");

        return [
          for (int i = 0; i < widgets.length; i++) ...[
            widgets[i],
            if (i != widgets.length - 1) const SizedBox(height: 3),
          ]
        ];
      }

      String imgFileName = imageExplorer[index].getFilenameString();
      _progressDialog.hide();
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 50),
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gambar $imgFileName",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Image.memory(
                          Uint8List.fromList(
                            dataParse["img"],
                          ),
                        ),
                      ),

                      // for handle v2.21
                      if (double.parse(imageMetaData.version ?? "0.0") < 2.21)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Text(listImageExplorer[index]
                                    .getDirIndexString())),
                            ...buildMetadataTextsV2(imageMetaData),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Text(listImageExplorer[index]
                                    .getDirIndexString())),
                            ...buildMetadataTextsV3(imageMetaData)
                          ],
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  _progressDialog.show(
                                      message: "Harap tunggu hasil unggah...");

                                  http.Response resultUpload = await ToServer()
                                      .postRequest(
                                          num.parse(imageMetaData.version ??
                                                      "0.0") >=
                                                  2.21
                                              ? "https://toppi-entrypoint-v3.bimasaktisanjaya.net/upload"
                                              : configProvider
                                                  .config.urlHelpUpload,
                                          // configProvider.config.urlHelpUpload,
                                          dataBuffer.data ?? [],
                                          imageMetaData
                                          // dataParse['img'],
                                          );
                                  _progressDialog.hide();
                                  if (resultUpload.statusCode == 200) {
                                    // update the filename
                                    bool ch = checkIfFirstWordAsExpect(
                                      listImageExplorer[index]
                                          .getFilenameString(),
                                      1,
                                    );
                                    if (!ch) {
                                      imgFileName =
                                          renameFileTo(imgFileName, 1);
                                      CommandImageFile().imageFileRename(
                                        bleProvider,
                                        listImageExplorer[index].dirIndex,
                                        listImageExplorer[index].filename,
                                        1,
                                      );
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }

                                    // refresh
                                    onRefresh();
                                  }
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return SimpleDialog(
                                        title: const Text("Hasil Unggah"),
                                        children: [
                                          SimpleDialogOption(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Kode Status : ${resultUpload.statusCode}",
                                                ),
                                                Text(
                                                    "Data : ${resultUpload.body}")
                                              ],
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  );
                                } catch (e) {
                                  _progressDialog.hide();
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return SimpleDialog(
                                          title: const Text("Hasil Unggah"),
                                          children: [
                                            SimpleDialogOption(
                                              child: Text(
                                                  "Error dapat unggah : $e"),
                                            )
                                          ],
                                        );
                                      });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Text(
                                  "Unggah",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  _progressDialog.show(
                                      message: "Harap tunggu hasil OCR...");

                                  http.Response resultOCR =
                                      await ToServer().postRequest(
                                    configProvider.config.urlTestOCR,
                                    dataBuffer.data ?? [],
                                    imageMetaData,
                                  );

                                  _progressDialog.hide();

                                  // String newResultFormat =
                                  //     ToServer.formatResponse(resultOCR);
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return SimpleDialog(
                                        title: const Text("Hasil OCR"),
                                        children: [
                                          SimpleDialogOption(
                                            child: Text(
                                              "Kode Status : ${resultOCR.statusCode}\nData : ${resultOCR.body}",
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  );
                                } catch (e) {
                                  _progressDialog.hide();
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return SimpleDialog(
                                          title: const Text("Hasil OCR"),
                                          children: [
                                            SimpleDialogOption(
                                              child:
                                                  Text("Error dapat OCR : $e"),
                                            )
                                          ],
                                        );
                                      });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Text(
                                  "Tes OCR",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  var status =
                                      await Permission.storage.request();
                                  if (!status.isGranted) {
                                    Snackbar.show(
                                      ScreenSnackbar.imageexplorerscreen,
                                      "Izin penyimpanan ditolak",
                                      success: false,
                                    );
                                    return;
                                  }
                                  DateTime dateTime = DateTime.now();
                                  String datetimenow =
                                      DateFormat('yyyyMMddHHmmss')
                                          .format(dateTime);
                                  String fileName =
                                      "img_${imageExplorer[index].getFilenameString()}_$datetimenow.jpg";
                                  if (mounted) {
                                    await DownloadUtils.saveToDownload(
                                      context,
                                      ScreenSnackbar.imageexplorerscreen,
                                      dataParse["img"],
                                      fileName,
                                    );
                                  }
                                } catch (e) {
                                  log("error : $e");
                                  Snackbar.show(
                                    ScreenSnackbar.imageexplorerscreen,
                                    "Gagal dapat menyimpan gambar : $e",
                                    success: false,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Text(
                                  "Simpan",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                BLEResponse resBLE =
                                    await _commandImageFile.imageFileDelete(
                                  bleProvider,
                                  imageExplorer[index].dirIndex,
                                  imageExplorer[index].filename,
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                                listImageExplorer.removeAt(index);
                                setState(() {});
                                if (resBLE.status) {
                                  Snackbar.show(
                                    ScreenSnackbar.imageexplorerscreen,
                                    resBLE.message,
                                    success: true,
                                  );
                                  // onRefresh();
                                  // return;
                                } else {
                                  Snackbar.show(
                                    ScreenSnackbar.imageexplorerscreen,
                                    resBLE.message,
                                    success: false,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Text(
                                  "Hapus",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        },
      );
    } catch (e) {
      Snackbar.show(
        ScreenSnackbar.imageexplorerscreen,
        "Error layar daftar gambar : $e",
        success: false,
      );
    }
  }

  Future<void> onRefresh() async {
    setState(() {
      listImageExplorer.clear();
      initGetImageExplorer();
    });
    _refreshController.refreshCompleted();
  }

  String renameFileTo(String nameStr, int to) {
    try {
      nameStr.replaceRange(0, 1, to.toString());
      return nameStr;
    } catch (e) {
      return nameStr;
    }
  }

  bool checkIfFirstWordAsExpect(String nameStr, int expect) {
    try {
      String first = nameStr[0];
      return int.parse(first) == expect;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyImageExplorerScreen,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Daftar $title'),
          elevation: 0,
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
                        getBufferDataImageFile(
                          listImageExplorer,
                          index,
                        );
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(top: 8, left: 5, right: 5),
                        padding: const EdgeInsets.only(
                            left: 13, right: 10, top: 2, bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.photo,
                              color: Colors.grey.shade700,
                              size: 22,
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color:
                                          listImageExplorer[index].dirIndex == 0
                                              ? Colors.green
                                              : Colors.blue,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.image_outlined,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            listImageExplorer[index]
                                                .getDirIndexString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    listImageExplorer[index]
                                        .getFilenameString(),
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
                                              listImageExplorer[index]
                                                  .getDateTimeString(),
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
                                              listImageExplorer[index]
                                                  .getFileSizeString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
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
                  childCount: listImageExplorer.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ButtonImageExplorer extends StatelessWidget {
  const ButtonImageExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
