import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/converter/status/status.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../admin_settings_screen/admin_settings_screen.dart';

class FilesScreen extends StatefulWidget {
  final BluetoothDevice device;

  const FilesScreen({super.key, required this.device});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  final RefreshController _refreshController = RefreshController();
  String statusTxt = "-",
      dirNearTxt = "-",
      dirNearUnsetTxt = "-",
      dirImageTxt = "-",
      dirImageUnsetTxt = "-",
      dirLogTxt = "-";

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  bool isFileScreen = true;
  late SimpleFontelicoProgressDialog _progressDialog;
  TextEditingController spCaptureDateTxtController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
    initGetFiles();
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    isFileScreen = false;
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
  }

  onRefresh() async {
    try {
      initGetFiles();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetFiles() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("files?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Files", device);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings, "Error get files : $e",
          success: false);
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 1));
    if (isConnected) {
      try {
        _services = await device.discoverServices();
        initLastValueSubscription(device);
      } catch (e) {
        Snackbar.show(ScreenSnackbar.capturesettings,
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
              if (characters.properties.notify && isFileScreen) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length >= 11) {
                  List<dynamic> result =
                      StatusConverter.convertFileStatus(_value);
                  _progressDialog.hide();

                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      dirNearTxt = result[1].toString();
                      dirNearUnsetTxt = result[2].toString();
                      dirImageTxt = result[3].toString();
                      dirImageUnsetTxt = result[4].toString();
                      dirLogTxt = result[5].toString();
                    });
                  }
                }

                if (mounted) {
                  setState(() {});
                }
              }
            },
            cancelOnError: true,
          );
          // _lastValueSubscription.cancel();
        }
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyFileScreen,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Files'),
          elevation: 0,
        ),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 0),
                    child: Column(
                      children: [
                        SettingsContainer(
                          title: "Status",
                          data: statusTxt,
                          onTap: () {},
                          icon: const Icon(
                            CupertinoIcons.settings,
                          ),
                        ),
                        SettingsContainer(
                          title: "Dir Near",
                          data: dirNearTxt,
                          onTap: () {},
                          icon: const Icon(
                            Icons.folder_open,
                          ),
                        ),
                        SettingsContainer(
                          title: "Dir Near Unsent",
                          data: dirNearUnsetTxt,
                          onTap: () {},
                          icon: const Icon(Icons.folder),
                        ),
                        SettingsContainer(
                          title: "Dir Image",
                          data: dirImageTxt,
                          onTap: () {},
                          icon: const Icon(
                            Icons.folder_special_outlined,
                          ),
                        ),
                        SettingsContainer(
                          title: "Dir Image Unset",
                          data: dirImageUnsetTxt,
                          onTap: () {},
                          icon: const Icon(
                            Icons.folder_special_rounded,
                          ),
                        ),
                        SettingsContainer(
                          title: "Dir Log",
                          data: dirLogTxt,
                          onTap: () {},
                          icon: const Icon(
                            Icons.snippet_folder_outlined,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
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
