import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/image_model.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/ble_main_screen/image_explorer_screen/list_image_explorer_screen.dart/list_image_explorer_screen.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../admin_settings_screen/admin_settings_screen.dart';

class ImageExplorerScreen extends StatefulWidget {
  final BluetoothDevice device;

  const ImageExplorerScreen({super.key, required this.device});

  @override
  State<ImageExplorerScreen> createState() => _ImageExplorerScreenState();
}

class _ImageExplorerScreenState extends State<ImageExplorerScreen> {
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  final RefreshController _refreshController = RefreshController();
  String dirAllTxt = "-",
      dirAllSentTxt = "-",
      dirAllUnsentTxt = "-",
      dirNearAllTxt = "-",
      dirNearSentTxt = "-",
      dirNearUnsentTxt = "-",
      dirImageAllTxt = "-",
      dirImageSentTxt = "-",
      dirImageUnsentTxt = "-";

  TextEditingController controller = TextEditingController();
  late SimpleFontelicoProgressDialog _progressDialog;
  TextEditingController spCaptureDateTxtController = TextEditingController();

  @override
  void initState() {
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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
      BLEResponse<ImageModel> res = await Command().getImage(bleProvider);
      _progressDialog.hide();
      if (res.status) {
        setState(() {
          dirAllTxt = res.data!.allImage.toString();
          dirAllSentTxt = res.data!.allSent.toString();
          dirNearSentTxt = res.data!.nearAll.toString();
          dirNearUnsentTxt = res.data!.nearUnsent.toString();
          dirImageSentTxt = res.data!.selfAll.toString();
          dirImageUnsentTxt = res.data!.selfUnsent.toString();
          // dirLogTxt = res.data!.dirLogTxt!;
        });
      } else {
        Snackbar.show(ScreenSnackbar.capturesettings, res.message,
            success: false);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings, "Dapat Error berkas : $e",
          success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyFileScreen,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Berkas Gambar'),
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
                        FeatureWidget(
                          title: "Semua Gambar",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.allFile;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Semua Gambar",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_open,
                          ),
                        ),
                        FeatureWidget(
                          title: "Semua Gambar Terkirim",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.allSent;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Semua Gambar Terkirim",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_open,
                          ),
                        ),
                        FeatureWidget(
                          title: "Semua Gambar Belum Terkirim",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.allUnsent;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Semua Gambar Belum Terkirim",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_open,
                          ),
                        ),
                        FeatureWidget(
                          title: "Semua Gambar Toppi Ini",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.imgAll;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Semua Gambar Toppi Ini",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_special_outlined,
                          ),
                        ),
                        FeatureWidget(
                          title: "Gambar Toppi Ini Terkirim",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.imgSent;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Gambar Ini Terkirim",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_special_outlined,
                          ),
                        ),
                        FeatureWidget(
                          title: "Gambar Toppi Ini Belum Terkirim",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.imgUnsent;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Gambar Toppi Ini Belum Terkirim",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_special_outlined,
                          ),
                        ),
                        FeatureWidget(
                          title: "Semua Gambar Toppi Lain",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.nearAll;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Semua Gambar Toppi Lain",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_outlined,
                          ),
                        ),
                        FeatureWidget(
                          title: "Gambar Toppi Lain Terkirim",
                          onTap: () {
                            int filter = ParameterImageExplorerFilter.nearSent;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Gambar Toppi Lain Terkirim",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.folder_outlined,
                          ),
                        ),
                        FeatureWidget(
                          title: "Gambar Toppi Lain Belum Terkirim",
                          onTap: () {
                            int filter =
                                ParameterImageExplorerFilter.nearUnsent;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListImageExplorerScreen(
                                    filter: filter,
                                    title: "Gambar Toppi Lain Belum Terkirim",
                                    device: device),
                              ),
                            );
                          },
                          icon: const Icon(Icons.folder_outlined),
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
