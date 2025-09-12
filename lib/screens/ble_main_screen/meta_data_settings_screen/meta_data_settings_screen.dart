import 'dart:async';
import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/meta_data_model.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../ble-v2/command/command_set.dart';
import '../../../utils/snackbar.dart';
import 'package:ble_test/utils/extension/extension.dart';

class MetaDataSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const MetaDataSettingsScreen({super.key, required this.device});

  @override
  State<MetaDataSettingsScreen> createState() => _MetaDataSettingsScreenState();
}

class _MetaDataSettingsScreenState extends State<MetaDataSettingsScreen> {
  late BLEProvider bleProvider;
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
  _connectionStateSubscription;
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  String meterModelTxt = '-',
      meterSnTxt = '-',
      meterSealTxt = '-',
      idPelangganTxt = '-';
  TextEditingController controller = TextEditingController();
  TextEditingController meterModelTxtController = TextEditingController();
  TextEditingController meterSnTxtController = TextEditingController();
  TextEditingController meterSealTxtController = TextEditingController();
  TextEditingController idPelangganTxtController = TextEditingController();

  late SimpleFontelicoProgressDialog _progressDialog;

  // v2
  late MetaDataModel metaData;
  final _commandSet = CommandSet();

  // v2 handle >= 2.21
  TextEditingController numberDigitTxtController = TextEditingController();
  TextEditingController numberDecimalTxtController = TextEditingController();
  TextEditingController customTxtController = TextEditingController();

  String customTxt = "-", numberDigitTxt = "-", numberDecimalTxt = "-";

  @override
  void initState() {
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressDialog = SimpleFontelicoProgressDialog(
        context: context,
        barrierDimisable: true,
      );
      _showLoading();
    });
    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (_connectionState == BluetoothConnectionState.disconnected) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      if (mounted) {
        setState(() {});
      }
    });

    initGetMetaData();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();

    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(message: "Harap Tunggu...");
  }

  onRefresh() async {
    try {
      initGetMetaData();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetMetaData() async {
    try {
      if (isConnected) {
        metaData = MetaDataModel(
          meterModel: "-",
          meterSN: "-",
          meterSeal: "-",
          custom: "-",
          paramCount: 4,
        );
        BLEResponse<MetaDataModel> response = await Command().getMetaData(
          bleProvider,
        );
        _progressDialog.hide();
        if (response.status) {
          metaData = response.data!;
          setState(() {
            meterModelTxt = response.data!.meterModel.changeEmptyString();
            meterSnTxt = response.data!.meterSN.changeEmptyString();
            meterSealTxt = response.data!.meterSeal.changeEmptyString();
            if (metaData.paramCount == 4) {
              customTxt = response.data!.custom.changeEmptyString();
            } else {
              idPelangganTxt = (response.data!.customerID ?? "-")
                  .changeEmptyString();
              numberDigitTxt = response.data!.numberDigit.toString();
              numberDecimalTxt = response.data!.numberDecimal.toString();
              customTxt = response.data!.custom.changeEmptyString();
            }
          });
        } else {
          Snackbar.show(
            ScreenSnackbar.metadatasettings,
            response.message,
            success: false,
          );
        }
      }
    } catch (e) {
      Snackbar.show(
        ScreenSnackbar.metadatasettings,
        "Dapat error meta data : $e",
        success: false,
      );
    }
  }

  Future<String?> _showInputDialog(
    TextEditingController controller,
    String field, {
    List<TextInputFormatter>? addInputFormatters,
    TextInputType? keyboardType,
  }) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        List<TextInputFormatter>? inputFormatters = [
          // FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
        ];
        if (addInputFormatters != null) {
          inputFormatters.addAll(addInputFormatters);
        }
        return AlertDialog(
          title: Text("Masukan data $field"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType ?? TextInputType.text,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                labelText: "Masukan $field",
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Input cannot be empty!")),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    return input;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyMetadataSettings,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Meta Data'), elevation: 0),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    SettingsContainer(
                      title: "Model Meter",
                      data: meterModelTxt,
                      onTap: () async {
                        if (!featureA.contains(roleUser)) {
                          return;
                        }
                        meterModelTxtController.text = meterModelTxt;
                        String? input = await _showInputDialog(
                          meterModelTxtController,
                          "Model Meter",
                          addInputFormatters: [
                            LengthLimitingTextInputFormatter(16),
                          ],
                        );
                        if (input != null && input.isNotEmpty) {
                          metaData.meterModel = input;
                          BLEResponse resBLE = await _commandSet.setMetaData(
                            bleProvider,
                            metaData,
                          );
                          Snackbar.showHelperV2(
                            ScreenSnackbar.metadatasettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(Icons.model_training_rounded),
                    ),
                    SettingsContainer(
                      title: "Nomor Seri Meter",
                      data: meterSnTxt,
                      onTap: () async {
                        if (!featureA.contains(roleUser)) {
                          return;
                        }
                        meterSnTxtController.text = meterSnTxt;
                        String? input = await _showInputDialog(
                          meterSnTxtController,
                          "Nomor Seri Meter",
                          addInputFormatters: [
                            LengthLimitingTextInputFormatter(16),
                          ],
                        );
                        if (input != null && input.isNotEmpty) {
                          metaData.meterSN = input;
                          BLEResponse resBLE = await _commandSet.setMetaData(
                            bleProvider,
                            metaData,
                          );
                          Snackbar.showHelperV2(
                            ScreenSnackbar.metadatasettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(Icons.numbers_rounded),
                    ),
                    SettingsContainer(
                      title: "Segel Meter",
                      data: meterSealTxt,
                      onTap: () async {
                        if (!featureA.contains(roleUser)) {
                          return;
                        }
                        meterSealTxtController.text = meterSealTxt;
                        String? input = await _showInputDialog(
                          meterSealTxtController,
                          "Segel Meter",
                          addInputFormatters: [
                            LengthLimitingTextInputFormatter(16),
                          ],
                        );
                        if (input != null && input.isNotEmpty) {
                          metaData.meterSeal = input;
                          BLEResponse resBLE = await _commandSet.setMetaData(
                            bleProvider,
                            metaData,
                          );
                          Snackbar.showHelperV2(
                            ScreenSnackbar.metadatasettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(Icons.shield_outlined),
                    ),
                    (metaData.paramCount == 4)
                        ? SettingsContainer(
                            title: "ID Pelanggan",
                            data: customTxt,
                            onTap: () async {
                              if (!featureA.contains(roleUser)) {
                                return;
                              }
                              idPelangganTxtController.text = customTxt;
                              String? input = await _showInputDialog(
                                idPelangganTxtController,
                                "Id Pelanggan",
                                addInputFormatters: [
                                  LengthLimitingTextInputFormatter(20),
                                ],
                              );
                              if (input != null && input.isNotEmpty) {
                                metaData.custom = input;
                                BLEResponse resBLE = await _commandSet
                                    .setMetaData(bleProvider, metaData);
                                Snackbar.showHelperV2(
                                  ScreenSnackbar.metadatasettings,
                                  resBLE,
                                  onSuccess: onRefresh,
                                );
                              }
                            },
                            icon: const Icon(Icons.description_rounded),
                          )
                        : Column(
                            children: [
                              SettingsContainer(
                                title: "ID Pelanggan",
                                data: idPelangganTxt,
                                onTap: () async {
                                  if (!featureA.contains(roleUser)) {
                                    return;
                                  }
                                  idPelangganTxtController.text =
                                      idPelangganTxt;
                                  String? input = await _showInputDialog(
                                    idPelangganTxtController,
                                    "Id Pelanggan",
                                    addInputFormatters: [
                                      LengthLimitingTextInputFormatter(20),
                                    ],
                                  );
                                  if (input != null && input.isNotEmpty) {
                                    metaData.customerID = input;
                                    BLEResponse resBLE = await _commandSet
                                        .setMetaData(bleProvider, metaData);
                                    Snackbar.showHelperV2(
                                      ScreenSnackbar.metadatasettings,
                                      resBLE,
                                      onSuccess: onRefresh,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.description_rounded),
                              ),
                              SettingsContainer(
                                title: "Angka didepan koma",
                                data: numberDigitTxt,
                                onTap: () async {
                                  if (!featureA.contains(roleUser)) {
                                    return;
                                  }
                                  numberDigitTxtController.text =
                                      numberDigitTxt;
                                  String? input = await _showInputDialog(
                                    numberDigitTxtController,
                                    "Angka didepan koma",
                                    keyboardType: TextInputType.number,
                                    addInputFormatters: [
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                  );
                                  if (input != null && input.isNotEmpty) {
                                    metaData.numberDigit = int.parse(input);
                                    BLEResponse resBLE = await _commandSet
                                        .setMetaData(bleProvider, metaData);
                                    Snackbar.showHelperV2(
                                      ScreenSnackbar.metadatasettings,
                                      resBLE,
                                      onSuccess: onRefresh,
                                    );
                                  }
                                },
                                icon: const Icon(CupertinoIcons.number_circle),
                              ),
                              SettingsContainer(
                                title: "Angka dibelakang koma",
                                data: numberDecimalTxt,
                                onTap: () async {
                                  if (!featureA.contains(roleUser)) {
                                    return;
                                  }
                                  numberDecimalTxtController.text = customTxt;
                                  String? input = await _showInputDialog(
                                    numberDecimalTxtController,
                                    "Angka dibelakang koma",
                                    keyboardType: TextInputType.number,
                                    addInputFormatters: [
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                  );
                                  if (input != null && input.isNotEmpty) {
                                    metaData.numberDecimal = int.parse(input);
                                    BLEResponse resBLE = await _commandSet
                                        .setMetaData(bleProvider, metaData);
                                    Snackbar.showHelperV2(
                                      ScreenSnackbar.metadatasettings,
                                      resBLE,
                                      onSuccess: onRefresh,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.number_circle_fill,
                                ),
                              ),
                              SettingsContainer(
                                title: "Custom",
                                data: customTxt,
                                onTap: () async {
                                  if (!featureA.contains(roleUser)) {
                                    return;
                                  }
                                  customTxtController.text = customTxt;
                                  String? input = await _showInputDialog(
                                    customTxtController,
                                    "Custom",
                                    addInputFormatters: [
                                      LengthLimitingTextInputFormatter(36),
                                    ],
                                  );
                                  if (input != null && input.isNotEmpty) {
                                    metaData.custom = input;
                                    BLEResponse resBLE = await _commandSet
                                        .setMetaData(bleProvider, metaData);
                                    Snackbar.showHelperV2(
                                      ScreenSnackbar.metadatasettings,
                                      resBLE,
                                      onSuccess: onRefresh,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.description_rounded),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
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

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
