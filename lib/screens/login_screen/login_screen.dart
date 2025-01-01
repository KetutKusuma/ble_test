import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/search_screen/search_screen.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ///==== for connection ble =====
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  List<BluetoothService> _services = [];
  StreamSubscription<List<int>>? _lastValueSubscription;

  late StreamSubscription<bool> _isScanningSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  List<int> _value = [];

  /// for login
  TextEditingController userRoleTxtController = TextEditingController();
  TextEditingController passwordTxtController = TextEditingController();
  TextEditingController macAddressTxtConroller = TextEditingController();
  TextEditingController idTxtController = TextEditingController();

  final PageController _pageController = PageController();

  List<String> pageListPumpDetail = [
    "Id",
    "Mac Address",
    "Scan",
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

  @override
  void initState() {
    getAppInfo();
    // TODO: implement initState
    super.initState();
    pd = SimpleFontelicoProgressDialog(
      context: context,
      barrierDimisable: true,
    );

    macAddressTxtConroller.addListener(() {
      _onTextChanged(macAddressTxtConroller);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      // log("listen scanning : ${firstInt}");
      if (state) {
        // pd.show(message: "Scanning...");
      } else {
        if (firstInt > 0) {
          if (!isFoundbyId && !isFoundbyMacAddress) {
            pd.hide();
            Snackbar.show(
              ScreenSnackbar.loginscreen,
              "Target Device Not Found",
              success: false,
            );
          }
        } else {
          firstInt = 1;
        }
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    isLoginScreen = false;
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
    valueHandshake.clear();
  }

  void getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    versionApp = packageInfo.version;
  }

  /// #2
  void connectProcess(BluetoothDevice device) async {
    // connect to device
    bool konek = await device.connectAndUpdateStream().catchError(
      (e) {
        pd.hide();
        log("FAILED CONNECT login screen");
        Snackbar.show(
            ScreenSnackbar.loginscreen, prettyException("Connect Error:", e),
            success: false);
      },
    );
    log("KONEK RESULT : $konek");

    // init discover services
    // it can be notify(subscribe) and listen lastvalue
    log("SUCCESS CONNECT login screen $isConnected");
    // pd.show(message: "Login process . . .");
    Future.delayed(const Duration(seconds: 4, milliseconds: 500));

    // listen for connection state
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        _connectionState = state;
        if (mounted) {
          setState(() {});
        }
      },
    );
    log("isconnected : $isConnected");
    // if (isConnected) {
    await initDiscoverServices(device);

    /// DO HANDSHAKE
    log("handshkae process . . .");

    List<int> list = utf8.encode("handshake?");
    Uint8List bytes = Uint8List.fromList(list);
    BLEUtils.funcWrite(bytes, "Handshake Success", device);

    // await for handshake cause handshake is importanto
    await Future.delayed(const Duration(seconds: 2));
    // LOGIN
    if (valueHandshake.isNotEmpty) {
      log("login process . . .");
      loginProcess(device);
    } else {
      pd.hide();
      Snackbar.show(
          ScreenSnackbar.loginscreen, "Login Failed! Value handshake is empty",
          success: false);
    }
    // }
  }

  loginProcess(BluetoothDevice device) async {
    List<int> forIV = valueHandshake + SALT1;
    List<int> forKey1 = valueHandshake + SALT2;
    List<int> forKey2 = valueHandshake + SALT3;

    String iv = md5.convert(forIV).toString();
    String key =
        md5.convert(forKey1).toString() + md5.convert(forKey2).toString();

    String resultAes256 = await CryptoAES256()
        .encryptCustomV2(key, iv, passwordTxtController.text);

    log("login=${userRoleTxtController.text};$resultAes256");
    String commLogin = "login=${userRoleTxtController.text};$resultAes256";
    List<int> list = utf8.encode(commLogin);
    Uint8List bytes = Uint8List.fromList(list);

    await BLEUtils.funcWrite(bytes, "Command login success", device);
    pd.hide();
  }

  /// #3
  Future initDiscoverServices(BluetoothDevice device) async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      _services = await device.discoverServices();
      initSubscription(device);
      // initLastValueSubscription(device);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.loginscreen,
          prettyException("Discover Services Error:", e),
          success: false);
      log("init discover services error : $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  // #5
  initLastValueSubscription(BluetoothCharacteristic c, BluetoothDevice device) {
    // ini disini harusnya ada algoritm untuk ambil data value notify
    // ketika handshake? ke write
    log("masuk ke init last value");
    try {
      if (_lastValueSubscription != null) {
        _lastValueSubscription!.cancel();
      }
      lastValueSubscription = c.lastValueStream.listen(
        (value) {
          log("is notifying ga nih : ${c.isNotifying}");
        },
        cancelOnError: true,
      );
      lastValueSubscription!.onData((data) {
        if (c.properties.notify && isLoginScreen) {
          lastValueG = data;
          log("_VALUE : $lastValueG");

          /// this is for login
          if (lastValueG.length == 1 && lastValueG[0] == 1) {
            pd.hide();
            if (userRoleTxtController.text == "admin") {
              roleUser = Role.ADMIN;
            } else if (userRoleTxtController.text == "operator") {
              roleUser = Role.OPERATOR;
            } else if (userRoleTxtController.text == "guest") {
              roleUser = Role.GUEST;
            }

            isLoginScreen = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BleMainScreen(
                  device: device,
                ),
              ),
            ).then((value) {
              firstInt = 0;
              isLoginScreen = true;
              userRoleTxtController.clear();
              passwordTxtController.clear();
              macAddressTxtConroller.clear();
              idTxtController.clear();
            });
          } else if (lastValueG.length == 1 && lastValueG[0] == 0) {
            Snackbar.show(
              ScreenSnackbar.loginscreen,
              "Login Failed",
              success: false,
            );
          }

          /// handshake
          if (lastValueG.length == 16) {
            log("LENGTH HANDSHAKE : ${lastValueG.length}");
            valueHandshake = lastValueG;
          }
          if (lastValueG.length != 16 && lastValueG.length != 1) {
            log("MAYBE FALSE CONNECT CHECK THE CONNECTION");
          }
          if (mounted) {
            setState(() {});
          }
        }
      });
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.loginscreen, prettyException("Last Value Error:", e),
          success: false);
      log("last value : $e");
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

  // #4
  void initSubscription(BluetoothDevice device) {
    for (var service in _services) {
      // log("characteristic : ${service.characteristics}");
      for (var characteristic in service.characteristics) {
        // log("ini true kah : ${characteristic.properties.notify}");
        if (characteristic.properties.notify) {
          // await characteristic
          subscribeProcess(characteristic, device);
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  /// #5.2
  Future subscribeProcess(
      BluetoothCharacteristic c, BluetoothDevice device) async {
    log("masuk sini tak ?");
    try {
      log('uhuy1');
      await c.setNotifyValue(true);
      log("masuk ke notifyingg bos ${c.isNotifying}");
      if (c.isNotifying) {
        initLastValueSubscription(c, device);
      }
      if (c.properties.read) {
        await c.read();
      }
      log("set value notify success");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.loginscreen, prettyException("Subscribe Error:", e),
          success: false);
      log("notify set error : $e");
    }
  }

  /// SEARH FOR DEVICES
  /// #1
  void searchForDevices() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    if (_scanResultsSubscription != null) {
      _scanResultsSubscription!.cancel();
    }
    pd.show(message: "Login process . . .");
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        log("SCAN RESULT : ${result}");
        log("SCAN RESULT DEVICE : ${result.device}");
        log("name : ${result.device.advName}");
        log("remote id : ${result.device.remoteId}");
        if (idTxtController.text.isNotEmpty) {
          if (result.device.advName.toString().toUpperCase() ==
              idTxtController.text.toUpperCase()) {
            log("Target Device by id found");
            FlutterBluePlus.stopScan(); // Stop scanning
            connectProcess(result.device);
            if (_scanResultsSubscription != null) {
              _scanResultsSubscription!.cancel();
            }
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
            isFoundbyMacAddress = true;
            break;
          }
        }
      }
    });
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
                        "Sign In",
                        style: GoogleFonts.readexPro(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Login to your TOPPI device",
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
                            labelText: "Username",
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
                          style: GoogleFonts.readexPro(),
                          cursorColor: Colors.transparent,
                          controller: passwordTxtController,
                          decoration: const InputDecoration(
                            labelText: "Password",
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
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20, bottom: 5),
                  child: Text("Choose a way to login",
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          indexPage = index;
                          _pageController.jumpToPage(index);
                          idTxtController.clear();
                          macAddressTxtConroller.clear();

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
                            inputFormatters: [],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (userRoleTxtController.text.isNotEmpty &&
                                  passwordTxtController.text.isNotEmpty) {
                                if (idTxtController.text.isNotEmpty) {
                                  searchForDevices();
                                }
                              } else {
                                Snackbar.show(ScreenSnackbar.loginscreen,
                                    "Please fill all form before login",
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
                                    "Login With Search Id",
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
                        /// mac address
                        children: [
                          const SizedBox(
                            height: 5,
                          ),
                          TextFormField(
                            style: GoogleFonts.readexPro(),
                            cursorColor: Colors.transparent,
                            controller: macAddressTxtConroller,
                            decoration: const InputDecoration(
                              labelText: "Mac Address",
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
                          GestureDetector(
                            onTap: () async {
                              if (userRoleTxtController.text.isNotEmpty &&
                                  passwordTxtController.text.isNotEmpty) {
                                if (macAddressTxtConroller.text.isNotEmpty) {
                                  searchForDevices();
                                }
                              } else {
                                Snackbar.show(ScreenSnackbar.loginscreen,
                                    "Please fill all form before login",
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
                                    "Login with Mac Address",
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
                                isLoginScreen = false;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchScreen(
                                      userRole: userRoleTxtController.text,
                                      password: passwordTxtController.text,
                                    ),
                                  ),
                                ).then((value) {
                                  firstInt = 0;
                                  isLoginScreen = true;
                                  userRoleTxtController.clear();
                                  passwordTxtController.clear();
                                });
                              } else {
                                Snackbar.show(ScreenSnackbar.loginscreen,
                                    "Please fill all form before login",
                                    success: false);
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
                                    "Login With Scan",
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
