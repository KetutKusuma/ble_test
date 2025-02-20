import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/meta_data_model.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../ble-v2/command/command_set.dart';
import '../../../utils/snackbar.dart';
import 'package:ble_test/utils/extension/string_extension.dart';

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
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String meterModelTxt = '-',
      meterSnTxt = '-',
      meterSealTxt = '-',
      customTxt = "-",
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

  @override
  void initState() {
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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

    initGetMetaData();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();

    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
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
        BLEResponse<MetaDataModel> response =
            await Command().getMetaData(bleProvider);
        _progressDialog.hide();
        if (response.status) {
          metaData = response.data!;
          setState(() {
            meterModelTxt = response.data!.meterModel.changeEmptyString();
            meterSnTxt = response.data!.meterSN.changeEmptyString();
            meterSealTxt = response.data!.meterSeal.changeEmptyString();
            customTxt = response.data!.custom.changeEmptyString();
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
          ScreenSnackbar.metadatasettings, "Dapat error meta data : $e",
          success: false);
    }
  }

  Future<String?> _showInputDialog(
      TextEditingController controller, String field,
      {List<TextInputFormatter>? addInputFormatters}) async {
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
              keyboardType: TextInputType.text,
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
        appBar: AppBar(
          title: const Text('Pengaturan Meta Data'),
          elevation: 0,
        ),
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
                        meterModelTxtController.text = meterModelTxt;
                        String? input = await _showInputDialog(
                          meterModelTxtController,
                          "Model Meter",
                          addInputFormatters: [
                            LengthLimitingTextInputFormatter(16)
                          ],
                        );
                        if (input != null && input.isNotEmpty) {
                          metaData.meterModel = input;
                          BLEResponse resBLE = await _commandSet.setMetaData(
                              bleProvider, metaData);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.metadatasettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.model_training_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Nomor Seri Meter",
                      data: meterSnTxt,
                      onTap: () async {
                        meterSnTxtController.text = meterSnTxt;
                        String? input = await _showInputDialog(
                            meterSnTxtController, "Nomor Seri Meter",
                            addInputFormatters: [
                              LengthLimitingTextInputFormatter(16)
                            ]);
                        if (input != null && input.isNotEmpty) {
                          metaData.meterSN = input;
                          BLEResponse resBLE = await _commandSet.setMetaData(
                              bleProvider, metaData);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.metadatasettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.numbers_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Segel Meter",
                      data: meterSealTxt,
                      onTap: () async {
                        meterSealTxtController.text = meterSealTxt;
                        String? input = await _showInputDialog(
                            meterSealTxtController, "Segel Meter",
                            addInputFormatters: [
                              LengthLimitingTextInputFormatter(16)
                            ]);
                        if (input != null && input.isNotEmpty) {
                          metaData.meterSeal = input;
                          BLEResponse resBLE = await _commandSet.setMetaData(
                              bleProvider, metaData);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.metadatasettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.shield_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "ID Pelanggan",
                      data: customTxt,
                      onTap: () async {
                        idPelangganTxtController.text = customTxt;
                        String? input = await _showInputDialog(
                            idPelangganTxtController, "Id Pelanggan",
                            addInputFormatters: [
                              LengthLimitingTextInputFormatter(32)
                            ]);
                        if (input != null && input.isNotEmpty) {
                          metaData.custom = input;
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
                      icon: const Icon(
                        Icons.description_rounded,
                      ),
                    ),
                    // SettingsContainer(
                    //   title: "Waktu UTC",
                    //   data: timeUTCTxt,
                    //   onTap: () async {
                    //     timeUTCTxtController.text = timeUTCTxt;
                    //     // String? input =
                    //     //     await _showInputDialogTimeUTC(timeUTCTxtController);
                    //     String? input =
                    //         await _showSelectionPopupUTC(context, utcList);
                    //     if (input != null) {
                    //       if (!input.contains("+") && !input.contains("-")) {
                    //         Snackbar.show(
                    //           ScreenSnackbar.metadatasettings,
                    //           "Masukan data waktu UTC dengan benar, kurang - atau +",
                    //           success: false,
                    //         );
                    //         return;
                    //       }
                    //       if (!input.contains(":")) {
                    //         Snackbar.show(
                    //           ScreenSnackbar.metadatasettings,
                    //           "Masukan data waktu UTC dengan benar, kurang :",
                    //           success: false,
                    //         );
                    //       } else {
                    //         int data = ConvertV2().utcStringToUint8(input);
                    //         // metaData.timeUTC = data;
                    //         BLEResponse resBLE = await _commandSet.setMetaData(
                    //           bleProvider,
                    //           metaData,
                    //         );
                    //         Snackbar.showHelperV2(
                    //           ScreenSnackbar.metadatasettings,
                    //           resBLE,
                    //           onSuccess: onRefresh,
                    //         );
                    //       }
                    //     }
                    //   },
                    //   icon: const Icon(
                    //     Icons.access_time,
                    //   ),
                    // ),
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
      // initDiscoverServices();
      await device.connectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.metadatasettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.metadatasettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.metadatasettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.metadatasettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.metadatasettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.metadatasettings,
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
