import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/search_screen/search_screen.dart';
import 'package:ble_test/untukuploadplaystore/searchscreen.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/crypto/crypto.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/global.dart';
import 'package:ble_test/utils/salt.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

class LoginScreenTest extends StatefulWidget {
  const LoginScreenTest({super.key});

  @override
  State<LoginScreenTest> createState() => _LoginScreenTestState();
}

class _LoginScreenTestState extends State<LoginScreenTest> {
  ///==== for connection ble =====

  final PageController _pageController = PageController();

  List<String> pageListPumpDetail = [
    "Id",
    "Alamat Mac",
    "Pemindaian",
  ];

  int indexPage = 0;
  late SimpleFontelicoProgressDialog pd;
  bool isLoginScreen = true;

  List<int> valueHandshake = [];
  bool isFoundbyId = false;
  bool isFoundbyMacAddress = false;
  static int firstInt = 0;

  // version app
  String versionApp = "1.0.0";

  // eye
  bool isObscureText = true;
  bool rememberMe = false;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    getAppInfo();
    // TODO: implement initState
    super.initState();
    pd = SimpleFontelicoProgressDialog(
      context: context,
      barrierDimisable: true,
    );
    getRememberMe();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    isLoginScreen = false;

    valueHandshake.clear();
    indexPage = 0;
  }

  void getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    versionApp = packageInfo.version;
  }

  void _onTextChanged(TextEditingController controller) {
    String text = controller.text.replaceAll(":", ""); // Remove existing colons
    String formattedText = "";

    // Add colon after every 2 characters
    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        formattedText += ":";
      }
    }

    // Prevent unnecessary updates (cursor position fixes)
    if (formattedText != controller.text) {
      final cursorPosition = controller.selection.baseOffset;
      controller.value = controller.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(
            offset: cursorPosition +
                (formattedText.length - controller.text.length)),
      );
    }
  }

  /// ==== FOR REMEMBER ME =====
  Future<void> rememberMeProcess(String username, String password,
      {String? id, String? macaddress}) async {
    if (rememberMe) {
      try {
        await storage.write(key: "username", value: username);
        await storage.write(key: "password", value: password);
        if (id != null) {
          await storage.write(key: "id", value: id);
        }
        if (macaddress != null) {
          await storage.write(key: "macaddress", value: macaddress);
        }
      } catch (e) {
        log("error write on secure storage : $e");
      }
    }
  }

  Future<void> getRememberMe() async {
    try {
      String? username = await storage.read(key: "username");
      String? password = await storage.read(key: "password");
      String? id = await storage.read(key: "id");
      String? macaddress = await storage.read(key: "macaddress");
    } catch (e) {
      log("error read on secure storage : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyLoginScreen,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.10,
                    ),
                    const Icon(
                      Icons.bluetooth_audio_rounded,
                      size: 30,
                    ),
                    Text(
                      "BLE-TOPPI",
                      style: GoogleFonts.readexPro(
                          fontSize: 35, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 30,
                    )
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Masuk",
                        style: GoogleFonts.readexPro(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Masuk ke perangkat Toppi Anda",
                        style: GoogleFonts.readexPro(),
                      )
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                // hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          style: GoogleFonts.readexPro(),
                          controller: TextEditingController(),
                          decoration: const InputDecoration(
                            labelText: "Nama Pengguna",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          obscureText: isObscureText,
                          style: GoogleFonts.readexPro(),
                          cursorColor: Colors.transparent,
                          controller: TextEditingController(),
                          decoration: InputDecoration(
                              labelText: "Kata Sandi",
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isObscureText = !isObscureText;
                                  });
                                },
                                child: Icon(
                                  isObscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              )),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    5.0), // Set the radius here
                              ),
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                            Text(
                              "Ingat Saya",
                              style: GoogleFonts.readexPro(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20, bottom: 5),
                  child: Text("Pilih cara untuk masuk",
                      style: GoogleFonts.readexPro()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: 2.45,
                  ),
                  itemCount: pageListPumpDetail.length,
                  itemBuilder: (context, index) {
                    // log("index page : $indexPage , index : $index");
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          indexPage = index;
                          _pageController.jumpToPage(index);
                          // if (index != 0) {
                          //   idTxtController.clear();
                          // }
                          // if (index != 1) {
                          //   macAddressTxtConroller.clear();
                          // }

                          setState(() {});
                        },
                        child: Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          color:
                              indexPage == index ? Colors.blue : Colors.white,
                          child: Center(
                            child: Text(
                              pageListPumpDetail[index],
                              style: GoogleFonts.readexPro(
                                color: indexPage != index
                                    ? Colors.blue
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    children: [
                      Column(
                        // login use id
                        children: [
                          const SizedBox(
                            height: 5,
                          ),
                          TextFormField(
                            style: GoogleFonts.readexPro(),
                            cursorColor: Colors.transparent,
                            controller: TextEditingController(),
                            decoration: const InputDecoration(
                              labelText: "Id",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            inputFormatters: [],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          // LOGIN WITH ID
                          GestureDetector(
                            onTap: () async {},
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Masuk dengan mencari Id",
                                    style: GoogleFonts.readexPro(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        /// login use mac address
                        children: [
                          const SizedBox(
                            height: 5,
                          ),
                          TextFormField(
                            style: GoogleFonts.readexPro(),
                            cursorColor: Colors.transparent,
                            controller: TextEditingController(),
                            decoration: const InputDecoration(
                              labelText: "Alamat Mac",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          // LOGIN WITH MAC ADDRESS
                          GestureDetector(
                            onTap: () async {},
                            child: Container(
                              margin: const EdgeInsets.only(top: 0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Masuk dengan Alamat Mac",
                                    style: GoogleFonts.readexPro(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // login use scan
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchScreenTest(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Masuk dengan pemindaian",
                                    style: GoogleFonts.readexPro(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody:
                    false, // Ensures it stretches to fill the remaining space
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Aligns the bottom section
                  children: [
                    Text(
                      "v$versionApp",
                      style: GoogleFonts.readexPro(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // connected

}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
