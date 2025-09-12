import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import 'package:yaml/yaml.dart';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
import 'package:ble_test/ble-v2/device_configuration/func_device_configuration.dart';
import 'package:ble_test/ble-v2/download_utils/download_utils.dart';
import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/utils/snackbar.dart';

class DeviceConfigurationScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceConfigurationScreen({super.key, required this.device});

  @override
  State<DeviceConfigurationScreen> createState() =>
      _DeviceConfigurationScreenState();
}

class _DeviceConfigurationScreenState extends State<DeviceConfigurationScreen> {
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  late SimpleFontelicoProgressDialog _progressDialog;
  String? filePath;
  String yamlContent = "";
  final ScrollController _scrollController = ScrollController();
  bool isMax = false;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _progressDialog = SimpleFontelicoProgressDialog(
      context: context,
      barrierDimisable: true,
    );
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
          Snackbar.show(
            ScreenSnackbar.deviceconfigurationscreen,
            "Perangkat Tidak Terhubung",
            success: false,
          );
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    checkScrollMax();
  }

  void onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    _refreshController.refreshCompleted();
    setState(() {});
  }

  Future<void> _pickFile() async {
    await FilePicker.platform.clearTemporaryFiles();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null) {
      final selectedFile = result.files.single;
      // Cek ekstensi secara manual
      if (selectedFile.extension == 'yaml' || selectedFile.extension == 'yml') {
        setState(() {
          filePath = selectedFile.path;
        });
        _loadYamlFile();
      } else {
        setState(() {
          yamlContent = "File yang dipilih bukan YAML.";
        });
      }
    }
  }

  Future<void> _loadYamlFile() async {
    if (filePath != null) {
      try {
        final file = File(filePath!);
        if (await file.exists()) {
          final content = await file.readAsString();
          setState(() {
            yamlContent = content;
          });
        } else {
          setState(() {
            yamlContent = "File tidak ditemukan.";
          });
        }
      } catch (e) {
        setState(() {
          yamlContent = "Gagal membaca file: $e";
        });
      }
    }
  }

  void checkScrollMax() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (isMax !=
            (_scrollController.position.pixels ==
                _scrollController.position.maxScrollExtent)) {
          isMax = true;
        } else {
          isMax = false;
        }
        setState(() {});
      } else {
        if (isMax !=
            (_scrollController.position.pixels ==
                _scrollController.position.maxScrollExtent)) {
          isMax = false;
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarDeviceConfiguration,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text("Konfigurasi Perangkat"),
        ),
        floatingActionButton: yamlContent == ""
            ? null
            : Container(
                margin: const EdgeInsets.only(bottom: 50),
                child: FloatingActionButton(
                  onPressed: () {
                    if (!isMax) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOut,
                      );
                      setState(() {});
                    } else {
                      _scrollController.animateTo(
                        _scrollController.position.minScrollExtent,
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOut,
                      );
                      setState(() {});
                    }
                  },
                  child: (isMax)
                      ? const Icon(Icons.keyboard_double_arrow_up)
                      : const Icon(
                          Icons.keyboard_double_arrow_down,
                        ),
                ),
              ),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    FeatureWidget(
                      title: "Download Konfigurasi",
                      onTap: () async {
                        try {
                          _progressDialog.show(
                            width: MediaQuery.of(context).size.width / 2,
                            backgroundColor: Colors.transparent,
                            message:
                                "Harap Tunggu Sedang Mendownload Konfigurasi...",
                            textStyle: const TextStyle(
                              color: Colors.white,
                            ),
                          );
                          DeviceConfiguration? dc =
                              await FunctionDeviceConfiguration()
                                  .getDeviceConfiguration(bleProvider);
                          if (dc == null) {
                            log("Gagal mendapatkan konfigurasi");
                            Snackbar.show(ScreenSnackbar.blemain,
                                "Gagal mendapatkan konfigurasi",
                                success: false);
                            _progressDialog.hide();
                            return;
                          }

                          if (mounted) {
                            _progressDialog.hide();
                            await DownloadUtils.backupYamlToDownload(
                              context,
                              ScreenSnackbar.deviceconfigurationscreen,
                              dc,
                            );
                          }
                        } catch (e) {
                          log("Gagal download konfigurasi : $e");
                          _progressDialog.hide();
                          Snackbar.show(
                            ScreenSnackbar.deviceconfigurationscreen,
                            "Gagal download konfigurasi : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(CupertinoIcons.arrow_down_doc),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(top: 8, left: 10, right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Implementasi Konfigurasi",
                            style: GoogleFonts.readexPro(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          yamlContent == ""
                              ? const SizedBox(
                                  height: 20,
                                )
                              : GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      yamlContent = "";
                                    });
                                  },
                                  child: const Align(
                                    alignment: Alignment.centerRight,
                                    child: Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 27,
                                    ),
                                  ),
                                ),
                          yamlContent == ""
                              ? GestureDetector(
                                  onTap: () {
                                    _pickFile();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        top: 0, left: 5, right: 5, bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.deepOrange,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.file_open_outlined,
                                              color: Colors.deepOrange,
                                              size: 32,
                                            ),
                                          ),
                                          Text(
                                            "Pilih Berkas Konfigurasi",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  margin: const EdgeInsets.only(
                                      top: 8, left: 10, right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 10),
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.black38,
                                      width: 1,
                                    ),
                                  ),
                                  child: SelectableText(
                                    yamlContent,
                                  ),
                                ),
                          yamlContent == ""
                              ? const SizedBox()
                              : Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          try {
                                            if (yamlContent == "") {
                                              Snackbar.show(
                                                ScreenSnackbar
                                                    .deviceconfigurationscreen,
                                                "Gagal impelementasi konfigurasi kosong",
                                                success: false,
                                              );
                                              return;
                                            }
                                            _progressDialog.show(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2,
                                              backgroundColor:
                                                  Colors.transparent,
                                              message:
                                                  "Harap Tunggu Sedang Implementasi Konfigurasi...",
                                              textStyle: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            );
                                            Map<String, dynamic> yamlMap =
                                                yamlToMap(
                                                    loadYaml(yamlContent));
                                            log("map : $yamlMap");

                                            DeviceConfiguration dc =
                                                DeviceConfiguration.fromJson(
                                                    yamlMap);

                                            // validate
                                            dc.validate();

                                            // set
                                            String res =
                                                await FunctionDeviceConfiguration()
                                                    .setDeviceConfiguration(
                                              bleProvider,
                                              dc,
                                            );
                                            _progressDialog.hide();

                                            Snackbar.show(
                                              ScreenSnackbar
                                                  .deviceconfigurationscreen,
                                              res,
                                              success: res.contains("Sukses"),
                                            );
                                          } catch (e) {
                                            _progressDialog.hide();
                                            log("error catch : $e");
                                            Snackbar.show(
                                              ScreenSnackbar
                                                  .deviceconfigurationscreen,
                                              "Error catch : $e",
                                              success: false,
                                            );
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              top: 8, left: 5, right: 5),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Implementasikan",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _pickFile,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              top: 8, left: 5, right: 5),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange[400],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Pilih Lainnya",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> yamlToMap(YamlMap yamlMap) {
    final map = <String, dynamic>{};
    yamlMap.forEach((key, value) {
      if (value is YamlMap) {
        map[key] = yamlToMap(value);
      } else if (value is YamlList) {
        map[key] = value.map((e) => e is YamlMap ? yamlToMap(e) : e).toList();
      } else {
        map[key] = value;
      }
    });
    return map;
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
