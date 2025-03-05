import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/untukuploadplaystore/capturescreen.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class BleMainScreenTest extends StatefulWidget {
  final BluetoothDevice device;

  const BleMainScreenTest({super.key, required this.device});

  @override
  State<BleMainScreenTest> createState() => _BleMainScreenTestState();
}

class _BleMainScreenTestState extends State<BleMainScreenTest> {
  @override
  void initState() {
    super.initState();
    // initMtuRequest();
    roleUser = Role.ADMIN;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    roleUser = Role.ADMIN;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Menu'),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  FeatureWidget(
                    visible: featureD.contains(roleUser),
                    title: "Pengaturan Admin",
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Pengaturan Pengambilan Gambar",
                    icon: const Icon(Icons.camera_alt_outlined),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Pengaturan Penerimaan Data",
                    icon: const Icon(Icons.download_outlined),
                    onTap: () {},
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Pengaturan Pengiriman Data",
                    icon: const Icon(CupertinoIcons.paperplane),
                    onTap: () {},
                  ),
                  Visibility(
                    visible: featureB.contains(roleUser),
                    child: FeatureWidget(
                      title: "Pengaturan Unggah Data",
                      icon: const Icon(Icons.upload_outlined),
                      onTap: () {},
                    ),
                  ),
                  FeatureWidget(
                    visible: featureB.contains(roleUser),
                    title: "Pengaturan Meta Data",
                    icon: const Icon(Icons.code),
                    onTap: () {},
                  ),
                  // FeatureWidget(
                  //   visible: featureD.contains(roleUser),
                  //   title: "Battery",
                  //   onTap: () {
                  //     if (isConnected) {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => BatteryScreen(device: device),
                  //         ),
                  //       );
                  //     } else {
                  //       Snackbar.showNotConnectedFalse(ScreenSnackbar.blemain);
                  //     }
                  //   },
                  //   icon: const Icon(
                  //     CupertinoIcons.battery_charging,
                  //   ),
                  // ),

                  FeatureWidget(
                    visible: featureC.contains(roleUser),
                    title: "Status Perangkat",
                    onTap: () {},
                    icon: const Icon(
                      CupertinoIcons.device_phone_portrait,
                    ),
                  ),
                  FeatureWidget(
                    visible: featureC.contains(roleUser),
                    title: "Ubah Password",
                    onTap: () {},
                    icon: const Icon(
                      Icons.lock_outlined,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CaptureScreenTest(device: widget.device),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.camera,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Pengambilan Gambar",
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
                  const SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () async {},
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Keluar",
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
                  const SizedBox(
                    height: 30,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureWidget extends StatelessWidget {
  const FeatureWidget({
    super.key,
    required this.title,
    required this.onTap,
    required this.icon,
    this.visible = true,
  });

  final String title;
  final void Function()? onTap;
  final Widget icon;
  final bool? visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible ?? true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
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
                  flex: 4,
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
                        width: 8,
                      ),
                      Expanded(
                        flex: 8,
                        child: Text(
                          title,
                          style: GoogleFonts.readexPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
