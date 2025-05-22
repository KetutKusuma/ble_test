import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/config/config.dart';
import 'package:ble_test/config/hidden.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/search_screen/search_screen.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late BLEProvider bleProvider;
  late ConfigProvider configProvider;

  ///==== for connection ble =====
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  late StreamSubscription<bool> _isScanningSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  /// for login
  TextEditingController userRoleTxtController = TextEditingController();
  TextEditingController passwordTxtController = TextEditingController();
  TextEditingController macAddressTxtConroller = TextEditingController();
  TextEditingController idTxtController = TextEditingController();

  final PageController _pageController = PageController();

  List<String> pageListPumpDetail = [
    "Id",
    "Alamat Mac",
    "Pemindaian",
  ];

  int indexPage = 0;
  late SimpleFontelicoProgressDialog pd;

  bool isFoundbyId = false;
  bool isFoundbyMacAddress = false;

  // version app
  String versionApp = "2.0.0";

  // eye
  bool isObscureText = true;
  bool rememberMe = false;
  final storage = const FlutterSecureStorage();
  int _tapCount = 0;
  int _tapCountBLE = 0;

  @override
  void initState() {
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    configProvider = Provider.of<ConfigProvider>(context, listen: false);
    configProvider.loadConfig();
    getAppInfo();

    super.initState();
    pd = SimpleFontelicoProgressDialog(
      context: context,
      barrierDimisable: true,
    );
    getRememberMe();

    macAddressTxtConroller.addListener(() {
      _onTextChanged(macAddressTxtConroller);
    });

    // this is for hidden
    idToppiHiddenTxtController.addListener(() {
      _onTextChanged(idToppiHiddenTxtController);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (_scanResultsSubscription != null) {
      _scanResultsSubscription!.cancel();
    }
    _isScanningSubscription.cancel();
    if (_connectionStateSubscription != null) {
      _connectionStateSubscription!.cancel();
    }
    userRoleTxtController.clear();
    passwordTxtController.clear();
    macAddressTxtConroller.clear();
    idTxtController.clear();
    indexPage = 0;
  }

  void getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    versionApp = packageInfo.version;
    setState(() {});
  }

  /// #2
  void connectProcess(BluetoothDevice device) async {
    await bleProvider.connect(device);
    Future.delayed(const Duration(seconds: 2, milliseconds: 500));
    // login new v2
    BLEResponse resHandshake = await Command().handshake(device, bleProvider);
    log("resHandshake : $resHandshake");
    if (resHandshake.status == false) {
      return;
    }
    List<int> challenge = resHandshake.data!;
    BLEResponse resLogin = await Command().login(
        device,
        bleProvider,
        userRoleTxtController.text.trim(),
        passwordTxtController.text.trim(),
        challenge);
    log("resLogin : $resLogin");
    pd.hide();
    if (resLogin.status == false) {
      Snackbar.show(
        ScreenSnackbar.loginscreen,
        resLogin.message,
        success: false,
      );
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BleMainScreen(device: device),
          ),
        );
      }
    }
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

  /// SEARH FOR DEVICES
  /// #1
  void searchForDevices() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    if (_scanResultsSubscription != null) {
      _scanResultsSubscription!.cancel();
    }
    pd.show(message: "Proses masuk . . .");
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (idTxtController.text.isNotEmpty) {
          if (result.device.advName.toString().toUpperCase() ==
              idTxtController.text.toUpperCase()) {
            log("Target Device by id found");
            FlutterBluePlus.stopScan(); // Stop scanning
            connectProcess(result.device);
            if (_scanResultsSubscription != null) {
              _scanResultsSubscription!.cancel();
            }
            storeSecureOptionLogin(indexPage);
            isFoundbyId = true;
            break;
          }
        }

        if (macAddressTxtConroller.text.isNotEmpty) {
          if (result.device.remoteId.toString().toUpperCase() ==
              macAddressTxtConroller.text.toUpperCase()) {
            log("Target Device by name found");
            FlutterBluePlus.stopScan();
            connectProcess(result.device);
            if (_scanResultsSubscription != null) {
              _scanResultsSubscription!.cancel();
            }
            storeSecureOptionLogin(indexPage);
            isFoundbyMacAddress = true;
            break;
          }
        }
      }
    });
  }

  // *******************************
  //! INI UNTUK TEST BLE OPSI LOGIN
  // *******************************
  Future<void> storeSecureOptionLogin(int loginWithValue) async {
    try {
      await storage.write(
        key: "login_with",
        value: loginWithValue.toString(),
      );
    } catch (e) {
      log('error write on secure storage option login : $e');
    }
  }

  Future<void> getSecureOptionLogin() async {
    try {
      String? option = await storage.read(key: "login_with");
      if (option != null) {
        indexPage = int.parse(option);
        _pageController.jumpTo(double.parse(option));
      } else {
        indexPage = 0;
        _pageController.jumpTo(0);
      }
    } catch (e) {
      log('error get on secure storage option login : $e');
    }
  }

  // *********************************
  //! ==== OPSI BLE END LOGIN =======
  // *********************************

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
      if (username != null && password != null) {
        userRoleTxtController.text = username;
        passwordTxtController.text = password;
        if (id != null) {
          idTxtController.text = id;
        }
        if (macaddress != null) {
          macAddressTxtConroller.text = macaddress;
        }
        rememberMe = true;
        setState(() {});
      } else {
        log("nothing found remember me");
      }
    } catch (e) {
      log("error read on secure storage : $e");
    }
  }

  String getVersion(String config) {
    if (config == "staging") {
      if (!versionApp.contains("-staging")) {
        versionApp = "$versionApp-staging";
      }
    } else {
      if (versionApp.contains("-staging")) {
        versionApp = versionApp.replaceAll("-staging", "");
      }
    }

    return "v$versionApp";
  }

  /// hanya untuk SUDO
  TextEditingController hardwareIDTxtController = TextEditingController();
  TextEditingController idToppiHiddenTxtController = TextEditingController();
  String theLicense = "12345678";

  void sendRequest(String hardwareID, String toppiID) async {
    try {
      log("data send : $hardwareID, $toppiID");
      final response = await Hidden()
          .sendRequest(hardwareID, toppiID, configProvider.config);
      log("data anying : $response");
      if (response.statusCode == 200) {
        setState(() {
          theLicense = jsonDecode(response.body)["message"];
        });
      } else {
        log('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error catch login send request: $e');
    }
  }

  Future<Map<String, dynamic>?> _showInputDialogForID({
    TextInputType? keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? lengthTextNeed = 0,
  }) async {
    Map<String, dynamic>? input = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          /// maunya disini buat fungsi tersembunyi bisa ngehit si license
          /// tapi entar aja
          title: const Text("Masukan HARDWARE ID dan ID TOPPI "),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                child: TextFormField(
                  controller: hardwareIDTxtController,
                  decoration: const InputDecoration(
                    labelText: "Masukan HARDWARE ID",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: keyboardType,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tolong diisi sebuah data';
                    }
                    return null;
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                    // FilteringTextInputFormatter
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Form(
                child: TextFormField(
                  controller: idToppiHiddenTxtController,
                  decoration: const InputDecoration(
                    labelText: "Masukan TOPPI ID",
                    border: OutlineInputBorder(),
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
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text("Lisensinya adalah : $theLicense"),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: theLicense));
                    },
                    child: const Icon(
                      Icons.copy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                idToppiHiddenTxtController.clear();
                hardwareIDTxtController.clear();
              },
              child: const Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                if (configProvider.config.config == "production") {
                  return;
                }
                sendRequest(
                  hardwareIDTxtController.text,
                  idToppiHiddenTxtController.text,
                );
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _tapCountBLE++;
                        });

                        if (_tapCountBLE == 5) {
                          _tapCountBLE = 0;
                          screenLock(
                            context: context,
                            correctString: "1111",
                            maxRetries: 1,
                            onMaxRetries: (value) {
                              Navigator.pop(context);
                            },
                            onUnlocked: () {
                              log("berhasil");
                              _showInputDialogForID(
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(14),
                                  // FilteringTextInputFormatter
                                ],
                                lengthTextNeed: 12,
                              );
                            },
                          );
                        }
                      },
                      child: Text(
                        "BLE-TOPPI",
                        style: GoogleFonts.readexPro(
                            fontSize: 35, fontWeight: FontWeight.bold),
                      ),
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
                          controller: userRoleTxtController,
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
                          controller: passwordTxtController,
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
                            controller: idTxtController,
                            decoration: const InputDecoration(
                              labelText: "Id",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            inputFormatters: const [],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          // LOGIN WITH ID
                          GestureDetector(
                            onTap: () async {
                              if (userRoleTxtController.text.isNotEmpty &&
                                  passwordTxtController.text.isNotEmpty) {
                                if (idTxtController.text.isNotEmpty) {
                                  // save user name and password process
                                  rememberMeProcess(
                                      userRoleTxtController.text.trim(),
                                      passwordTxtController.text.trim(),
                                      id: idTxtController.text.trim());
                                  searchForDevices();
                                }
                              } else {
                                Snackbar.show(ScreenSnackbar.loginscreen,
                                    "Tolong isi Nama Pengguna dan Kata Sandi sebelum masuk",
                                    success: false);
                              }
                            },
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
                            controller: macAddressTxtConroller,
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
                            onTap: () async {
                              if (userRoleTxtController.text.isNotEmpty &&
                                  passwordTxtController.text.isNotEmpty) {
                                if (macAddressTxtConroller.text.isNotEmpty) {
                                  // save user name and password process
                                  rememberMeProcess(
                                    userRoleTxtController.text.trim(),
                                    passwordTxtController.text.trim(),
                                    macaddress: macAddressTxtConroller.text,
                                  );

                                  searchForDevices();
                                }
                              } else {
                                Snackbar.show(ScreenSnackbar.loginscreen,
                                    "Tolong isi Nama Pengguna dan Kata Sandi sebelum masuk",
                                    success: false);
                              }
                            },
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
                              if (userRoleTxtController.text.isNotEmpty &&
                                  passwordTxtController.text.isNotEmpty) {
                                // save user name and password process
                                rememberMeProcess(
                                    userRoleTxtController.text.trim(),
                                    passwordTxtController.text.trim());
                                storeSecureOptionLogin(2);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchScreen(
                                      userRole: userRoleTxtController.text,
                                      password: passwordTxtController.text,
                                    ),
                                  ),
                                ).then((value) {
                                  indexPage = 0;
                                  _pageController.jumpToPage(0);
                                  // userRoleTxtController.clear();
                                  // passwordTxtController.clear();
                                });
                              } else {
                                Snackbar.show(
                                  ScreenSnackbar.loginscreen,
                                  "Tolong isi Nama Pengguna dan Kata Sandi sebelum masuk",
                                  success: false,
                                );
                              }
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _tapCount++;
                        });
                        log("tap count : $_tapCount");
                        if (_tapCount >= 10) {
                          configProvider.loadConfig();

                          _tapCount = 0;
                          return;
                        }
                      },
                      child: Text(
                        getVersion(configProvider.config.config),
                        style: GoogleFonts.readexPro(
                          fontSize: 15,
                          color: Colors.black45,
                        ),
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

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
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
