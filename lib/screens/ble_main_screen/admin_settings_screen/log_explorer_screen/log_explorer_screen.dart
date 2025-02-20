import 'dart:async';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_image_file_capture.dart';
import 'package:ble_test/ble-v2/model/sub_model/explorer/log_explorer.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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

  bool isGetting = true;
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

      Snackbar.show(
        ScreenSnackbar.logexplorerscreen,
        "Sukses dapat daftar catatan",
        success: true,
      );
    } catch (e) {
      Snackbar.show(
        ScreenSnackbar.logexplorerscreen,
        "Error layar daftar catatan : $e",
        success: false,
      );
    }
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
        body: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ListTile(
                    leading: Text(
                      listLogExplorer[index].getDateString(),
                    ),
                    title: Text(
                      listLogExplorer[index].getFilenameString(),
                    ),
                    trailing: Text(
                      listLogExplorer[index].getFileSizeString(),
                    ),
                  );
                },
                childCount: listLogExplorer.length,
              ),
            )
          ],
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
