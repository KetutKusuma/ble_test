import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';
import 'package:ble_test/ble-v2/model/admin_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_coefficient_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/camera_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/identity_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/global.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../constant/constant_color.dart';

class AdminSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;

  const AdminSettingsScreen({super.key, required this.device});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  String idTxt = '-',
      voltCoef1Txt = '-',
      voltCoef2Txt = '-',
      brightnessText = '-',
      contrastText = '-',
      saturationText = '-',
      specialEffectText = '-',
      hMirrorText = '-',
      vFlipText = '-',
      cameraJpgQualityTxt = '-',
      roleTxt = '-';

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController idTxtController = TextEditingController();
  TextEditingController voltageCoefTxtController = TextEditingController();
  TextEditingController cameraJpegQualityController = TextEditingController();

  final List<Map<String, dynamic>> dataMapRole = [
    {"title": "Tidak Terdefinisi", "value": 0},
    {"title": "Regular", "value": 1},
    {"title": "Gateway", "value": 2},
  ];
  final List<Map<String, dynamic>> dataMapBrightnessContrastSaturation = [
    {"title": "-2", "value": -2},
    {"title": "-1", "value": -1},
    {"title": "0", "value": 0},
    {"title": "1", "value": 1},
    {"title": "2", "value": 2},
  ];
  final List<Map<String, dynamic>> dataMapSpecialEffect = [
    {"title": "Tidak ada", "value": 0},
    {"title": "Negative", "value": 1},
    {"title": "Grayscale", "value": 2},
    {"title": "Red Tint", "value": 3},
    {"title": "Green Tint", "value": 4},
    {"title": "Blue Tint", "value": 5},
    {"title": "Sepia", "value": 6},
  ];
  List<int> bits = [];
  bool isAdminSettings = true;
  late SimpleFontelicoProgressDialog _progressDialog;

  // for get enable
  bool isGetEnable = false;
  String enableTxt = "-";

  // for get print to serial monitor
  String printToSerialMonitorTxt = "-";

  // v2
  late AdminModels adminModels;
  Command _command = Command();
  CommandSet _commandSet = CommandSet();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressDialog = SimpleFontelicoProgressDialog(
          context: context, barrierDimisable: true);
      _showLoading();
    });

    idTxtController.addListener(() {
      _onTextChanged(idTxtController);
    });
    voltageCoefTxtController.addListener(() {
      final text = voltageCoefTxtController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          if (value < 0.5 && text.length > 2) {
            // Otomatis set menjadi 0.5 jika kurang dari 0.5
            voltageCoefTxtController.text = '0.5';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          } else if (value > 1.5) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            voltageCoefTxtController.text = '1.5';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          }
        }
      }
    });
    cameraJpegQualityController.addListener(() {
      final text = voltageCoefTxtController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          if (value < 0) {
            // Otomatis set menjadi 0.5 jika kurang dari 0.5
            voltageCoefTxtController.text = '0';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          } else if (value > 63) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            voltageCoefTxtController.text = '63';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          }
        }
      }
    });

    initGetAdmin();
  }

  @override
  void dispose() {
    isAdminSettings = false;
    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
  }

  void _onTextChanged(TextEditingController textEditingController) {
    // Step 1: Remove invalid characters (allow only a-f, A-F, and 0-9)
    String text =
        textEditingController.text.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');

    // Step 2: Format the text with colons
    String formattedText = "";

    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        formattedText += ":";
      }
    }

    // Step 3: Prevent unnecessary updates and fix cursor position
    if (formattedText != textEditingController.text) {
      final cursorPosition = textEditingController.selection.baseOffset;
      textEditingController.value = textEditingController.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(
            offset: cursorPosition +
                (formattedText.length - textEditingController.text.length)),
      );
    }
  }

  onRefresh() async {
    try {
      initGetAdmin();
      await Future.delayed(
        const Duration(seconds: 1),
      );
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  String getRole(int role) {
    String roleS = "Tidak terdefinisi";
    if (role == 1) {
      roleS = "Regular";
    }
    if (role == 2) {
      roleS = "Gateway";
    }
    return roleS;
  }

  Future initGetAdmin() async {
    try {
      if (isConnected) {
        BLEResponse<AdminModels> adminResponse =
            await _command.getAdminData(device, bleProvider);
        _progressDialog.hide();
        log("admin response : $adminResponse");
        if (adminResponse.status) {
          adminModels = adminResponse.data!;
          idTxt = ConvertV2().arrayUint8ToStringHexAddress(
              adminResponse.data!.identityModel!.toppiID);
          voltCoef1Txt = adminResponse
              .data!.batteryCoefficientModel!.coefficient1
              .toString();
          voltCoef2Txt = adminResponse
              .data!.batteryCoefficientModel!.coefficient2
              .toString();
          brightnessText =
              adminResponse.data!.cameraModel!.brightness.toString();
          contrastText = adminResponse.data!.cameraModel!.contrast.toString();
          saturationText =
              adminResponse.data!.cameraModel!.saturation.toString();
          specialEffectText = getSpecialEffectString(
              adminResponse.data!.cameraModel!.specialEffect);
          hMirrorText = adminResponse.data!.cameraModel!.hMirror.toString();
          vFlipText = adminResponse.data!.cameraModel!.vFlip.toString();
          cameraJpgQualityTxt =
              adminResponse.data!.cameraModel!.jpegQuality.toString();
          roleTxt = getRole(adminResponse.data!.role ?? 0);
          enableTxt = adminResponse.data!.enable.toString();
          printToSerialMonitorTxt =
              adminResponse.data!.printToSerialMonitor.toString();
          setState(() {});
        } else {
          Snackbar.show(ScreenSnackbar.adminsettings, adminResponse.message,
              success: false);
        }
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.adminsettings, "Error get raw admin : $e",
          success: false);
    }
  }

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

  String getSpecialEffectString(int value) {
    switch (value) {
      case 0:
        return "Tidak Ada";
      case 1:
        return "Negative";
      case 2:
        return "Grayscale";
      case 3:
        return "Red Tint";
      case 4:
        return "Green Tint";
      case 5:
        return "Blue Tint";
      case 6:
        return "Sepia";
      default:
        return "None";
    }
  }

  /// ===== for connection ===================
  Future onConnectPressed() async {
    try {
      await device.connectAndUpdateStream();
      // initDiscoverServices();
      Snackbar.show(ScreenSnackbar.login, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(
            ScreenSnackbar.login, prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.login, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.login, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.login, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Disconnect Error:", e),
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

  Future<bool?> _showTrueFalseDialog(BuildContext context, String msg) async {
    bool? selectedValue = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(msg),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true); // Return true
              },
              child: const Text('Ya'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, false); // Return false
              },
              child: const Text('Tidak'),
            ),
          ],
        );
      },
    );

    return selectedValue;
  }

  // Function to show a dialog for input
  Future<String?> _showInputDialog(
    TextEditingController controller,
    String title, {
    String? label = '',
    TextInputType? keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? lengthTextNeed = 0,
  }) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Masukan $title"),
          content: Form(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Masukan $label",
                border: const OutlineInputBorder(),
              ),
              keyboardType: keyboardType,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tolong diisi sebuah data';
                }
                return null;
              },
              inputFormatters: inputFormatters,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.clear();
              },
              child: const Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                if (lengthTextNeed != 0 &&
                    lengthTextNeed! < controller.text.length) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
                }
                if (lengthTextNeed == 0) {
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

    return input;
  }

  Future<String?> _showInputDialogVoltage(
      TextEditingController controller) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Masukan data Koefisien Tegangan"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Nilai antara 0.5 and 1.5',
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
              child: const Text("Batalkan"),
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

    return input;
  }

  Future<Map?> _showSelectionPopup(
      BuildContext context, List<Map<String, dynamic>> dataMap) async {
    Map? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sebuah Opsi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: dataMap.map((item) {
              return ListTile(
                title: Text(item['title']),
                onTap: () {
                  Navigator.of(context).pop(item); // Return the selected item
                },
              );
            }).toList(),
          ),
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyAdminSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Admin'),
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
                    const SizedBox(
                      height: 10,
                    ),

                    SettingsContainer(
                      icon: const Icon(Icons.person_outline),
                      title: "ID",
                      data: idTxt,
                      onTap: () async {
                        idTxtController.text = idTxt;
                        String? input = await _showInputDialog(
                          idTxtController,
                          "New ID",
                          label: 'New ID ',
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(14),
                            // FilteringTextInputFormatter
                          ],
                          lengthTextNeed: 12,
                        );
                        log("input : $input");
                        if (input != null) {
                          List<int> dataSet = ConvertV2()
                              .stringHexAddressToArrayUint8(input, 5);
                          log("hasil data set : $dataSet");
                          IdentityModel identityUpdate =
                              adminModels.identityModel!;
                          identityUpdate.toppiID = dataSet;
                          BLEResponse resBLE = await _commandSet.setIdentity(
                            bleProvider,
                            identityUpdate,
                          );
                          Snackbar.showHelperV2(
                            ScreenSnackbar.adminsettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.bolt),
                        title: "Koefisien Tegangan 1",
                        data: voltCoef1Txt,
                        onTap: () async {
                          voltageCoefTxtController.text = voltCoef1Txt;
                          String? input = await _showInputDialogVoltage(
                              voltageCoefTxtController);
                          if (input != null) {
                            BatteryCoefficientModel batteryCoef =
                                adminModels.batteryCoefficientModel!;
                            log("inputan coef 1 : $input");
                            batteryCoef.coefficient1 = double.parse(input);
                            BLEResponse resBLE =
                                await _commandSet.setBatteryVoltageCoef(
                              bleProvider,
                              batteryCoef,
                            );
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.bolt),
                        title: "Koefisien Tegangan 2",
                        data: voltCoef2Txt,
                        onTap: () async {
                          voltageCoefTxtController.text = voltCoef2Txt;
                          String? input = await _showInputDialogVoltage(
                              voltageCoefTxtController);
                          if (input != null) {
                            BatteryCoefficientModel batteryCoef =
                                adminModels.batteryCoefficientModel!;
                            log("inputan coef 2 : $input");
                            batteryCoef.coefficient2 = double.parse(input);
                            BLEResponse resBLE =
                                await _commandSet.setBatteryVoltageCoef(
                              bleProvider,
                              batteryCoef,
                            );
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.brightness_5),
                        title: "Kecerahan Kamera",
                        data: brightnessText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapBrightnessContrastSaturation);
                          if (input != null) {
                            int dataUpdate = input['value'];
                            CameraModel camera = adminModels.cameraModel!;
                            camera.brightness = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.brightness_6),
                        title: "Kontras Kamera",
                        data: contrastText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapBrightnessContrastSaturation);
                          if (input != null) {
                            int dataUpdate = input['value'];
                            CameraModel camera = adminModels.cameraModel!;
                            camera.contrast = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.brightness_1_rounded),
                        title: "Saturasi Kamera",
                        data: saturationText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapBrightnessContrastSaturation);
                          if (input != null) {
                            int dataUpdate = input['value'];
                            CameraModel camera = adminModels.cameraModel!;
                            camera.saturation = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.wand_stars_inverse),
                        title: "Efek Khusus Kamera",
                        data: specialEffectText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapSpecialEffect);
                          if (input != null) {
                            int dataUpdate = input['value'];
                            CameraModel camera = adminModels.cameraModel!;
                            camera.specialEffect = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.flip),
                        title: "Cermin Horizontal Kamera",
                        data: hMirrorText == "true" ? "Ya" : "Tidak",
                        onTap: () async {
                          bool? input = await _showTrueFalseDialog(
                              context, "Cermin Horizontal Kamera");
                          if (input != null) {
                            bool dataUpdate = input;
                            CameraModel camera = adminModels.cameraModel!;
                            camera.hMirror = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: Transform.rotate(
                          angle: 3.14 / 2,
                          child: const Icon(
                            Icons.flip,
                          ),
                        ),
                        title: "Pembalikan Vertikal Kamera",
                        data: vFlipText == "true" ? "Ya" : "Tidak",
                        onTap: () async {
                          bool? input = await _showTrueFalseDialog(
                              context, "Pembalikan Vertikal Kamera");
                          if (input != null) {
                            bool dataUpdate = input;
                            CameraModel camera = adminModels.cameraModel!;
                            camera.vFlip = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(
                          Icons.high_quality_outlined,
                        ),
                        title: "Kualitas JPEG Kamera",
                        data: cameraJpgQualityTxt,
                        onTap: () async {
                          cameraJpegQualityController.text =
                              cameraJpgQualityTxt;
                          String? input = await _showInputDialog(
                            cameraJpegQualityController,
                            "Kualitas JPEG Kamera",
                            label: '0 to 63',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          );
                          log("input : $input");
                          if (input != null) {
                            int dataUpdate = int.parse(input);
                            CameraModel camera = adminModels.cameraModel!;
                            camera.jpegQuality = dataUpdate;
                            BLEResponse resBLE = await _commandSet.setCamera(
                                bleProvider, camera);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),

                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.gear_big),
                        title: "Role",
                        data: roleTxt,
                        onTap: () async {
                          Map? input =
                              await _showSelectionPopup(context, dataMapRole);
                          if (input != null) {
                            int dataUpdate = input['value'];
                            BLEResponse resBLE = await _commandSet.setRole(
                                bleProvider, dataUpdate);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                      ),
                    ),

                    Visibility(
                      visible: featureB.contains(roleUser),
                      child: SettingsContainer(
                        title: "Aktifkan Toppi",
                        data: enableTxt == "true" ? "Ya" : "Tidak",
                        onTap: () async {
                          bool? input = await _showTrueFalseDialog(
                              context, "Aktifkan Toppi");
                          if (input != null) {
                            BLEResponse resBLE =
                                await _commandSet.setEnable(bleProvider, input);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.check_circle_outline_outlined,
                        ),
                      ),
                    ),

                    // FOR PRINT TO SERIAL MONITOR
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        title: "Tampilkan ke Layar Serial",
                        data:
                            printToSerialMonitorTxt == "true" ? "Ya" : "Tidak",
                        onTap: () async {
                          bool? input = await _showTrueFalseDialog(
                              context, "Tampilkan ke Layar Serial");
                          if (input != null) {
                            BLEResponse resBLE = await _commandSet
                                .setPrintSerialMonitor(bleProvider, input);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.adminsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.print_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    /// RESET
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: GestureDetector(
                        onTap: () async {
                          // BLEResponse resBLE =
                          //     await _command(bleProvider, dataUpdate);
                          // Snackbar.showHelperV2(
                          //   ScreenSnackbar.adminsettings,
                          //   resBLE,
                          // );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.settings_backup_restore_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                "Reset",
                                style: GoogleFonts.readexPro(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// FORMAT
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: GestureDetector(
                        onTap: () async {
                          BLEResponse resBLE =
                              await _command.formatFAT(device, bleProvider);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.adminsettings,
                            resBLE,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.drive_file_move_rtl_outlined,
                                color: Colors.white,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                "Format Berkas",
                                style: GoogleFonts.readexPro(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
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
}

class SettingsContainer extends StatelessWidget {
  const SettingsContainer({
    super.key,
    required this.title,
    required this.data,
    required this.onTap,
    required this.icon,
    this.description,
  });

  final String title;
  final String? description;
  final String data;
  final void Function() onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 7, left: 10, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.contain,
                        child: icon,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 8,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.readexPro(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          (description == null)
                              ? const SizedBox()
                              : Text(
                                  description ?? '',
                                  style: GoogleFonts.readexPro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    data,
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SetSettingsModel {
  String setSettings = "";
  String value = "";

  SetSettingsModel({required this.setSettings, required this.value});
}
