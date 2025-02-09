import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/storage_model.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

class StorageScreen extends StatefulWidget {
  final BluetoothDevice device;

  const StorageScreen({super.key, required this.device});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  final RefreshController _refreshController = RefreshController();
  String getTotalBytesTxt = "-", getUsedBytesTxt = "-";

  TextEditingController controller = TextEditingController();
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
    initGetStorage();
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
      initGetStorage();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetStorage() async {
    try {
      BLEResponse<StorageModel> storageResponse =
          await Command().getStorage(bleProvider);
      _progressDialog.hide();
      if (storageResponse.status == false) {
        Snackbar.show(
          ScreenSnackbar.capturesettings,
          storageResponse.message,
          success: false,
        );
      } else {
        getTotalBytesTxt = formatBytes(storageResponse.data!.total);
        getUsedBytesTxt = formatBytes(storageResponse.data!.used);
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.capturesettings, "Dapat Error penyimpanan : $e",
          success: false);
    }
  }

  String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      // Jika data lebih dari 1 MB, ubah ke MB
      double mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      // Jika data lebih dari 1 KB tapi kurang dari 1 MB, ubah ke KB
      double kb = bytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else {
      // Jika data kurang dari 1 KB, biarkan dalam byte
      return '${bytes} Bytes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyStorageScreen,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Storage'),
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
                          title: "Total Penyimpanan",
                          data: getTotalBytesTxt,
                          onTap: () {},
                          icon: const Icon(
                            Icons.storage_rounded,
                          ),
                        ),
                        SettingsContainer(
                          title: "Penyimpanan Digunakan",
                          data: getUsedBytesTxt,
                          onTap: () {},
                          icon: const Icon(
                            Icons.storage_outlined,
                          ),
                        ),
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
