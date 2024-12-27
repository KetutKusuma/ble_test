import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/scan_screen/scan_screen.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/crypto/crypto.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/salt.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ///====
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  StreamSubscription<List<int>>? _lastValueSubscription;
  late BluetoothDevice _device;

  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  List<int> _value = [];

  /// for login
  TextEditingController userRoleTxtController = TextEditingController();
  TextEditingController passwordTxtController = TextEditingController();
  TextEditingController macAddressTxtConroller = TextEditingController();
  TextEditingController idTxtController = TextEditingController();

  final PageController _pageController = PageController();

  List<String> pageListPumpDetail = [
    'Mac Address',
    "Id",
    "Scan",
  ];

  int indexPage = 0;
  late SimpleFontelicoProgressDialog pd;
  bool isLoginScreen = true;

  List<int> valueHandshake = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pd = SimpleFontelicoProgressDialog(
      context: context,
      barrierDimisable: false,
    );

    idTxtController.addListener(_onTextChanged);
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (state) {
        pd.show(message: "Scanning...");
      } else {
        pd.hide();
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
  }

  /// Initiates the connection process with the given Bluetooth device.
  ///
  /// This function attempts to connect to the specified [device] and updates the
  /// connection stream. If an error occurs during the connection, it is caught and
  /// displayed as a snackbar message. After a delay, the MTU is requested to be set
  /// to 512. Upon successful connection, the progress dialog is hidden and the
  /// user is navigated to the BleMainScreen.
  void connectProcess(BluetoothDevice device) async {
    device.connectAndUpdateStream().catchError(
      (e) {
        Snackbar.show(
            ScreenSnackbar.loginscreen, prettyException("Connect Error:", e),
            success: false);
      },
    );
    log("SUCCESS CONNECT");
    Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    // request mtu 512
    device.requestMtu(512);

    /// DO HANDSHAKE
    List<int> list = utf8.encode("handshake?");
    Uint8List bytes = Uint8List.fromList(list);
    BLEUtils.funcWrite(bytes, "Handshake Success", device);

    // await for handshake cause handshake is importanto
    await Future.delayed(const Duration(seconds: 2));
    // LOGIN
    if (valueHandshake.isNotEmpty) {
      loginProcess(device);
    } else {
      Snackbar.show(
          ScreenSnackbar.loginscreen, "Login Failed! Value handshake is empty",
          success: false);
    }
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
  }

  Future initDiscoverServices(BluetoothDevice device) async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      _services = await device.discoverServices();
      initSubscription();
      initLastValueSubscription(_device);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.loginscreen,
          prettyException("Discover Services Error:", e),
          success: false);
      log(e.toString());
    }
    if (mounted) {
      setState(() {});
    }
  }

  initLastValueSubscription(BluetoothDevice device) {
    // ini disini harusnya ada algoritm untuk ambil data value notify
    // ketika handshake? ke write
    try {
      for (var service in device.servicesList) {
        for (var characters in service.characteristics) {
          // log("notify : ${characters.properties.notify}, isNotifying : $isNotifying");
          _lastValueSubscription = characters.lastValueStream.listen(
            (value) {
              log("is notifying ga nih : ${characters.isNotifying}");
              if (characters.properties.notify && isLoginScreen) {
                _value = value;
                log("_VALUE : $_value");

                /// this is for login
                if (_value.length == 1 && _value[0] == 1) {
                  pd.hide();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BleMainScreen(
                        device: _device,
                      ),
                    ),
                  );
                } else if (_value.length == 1 && _value[0] == 0) {
                  Snackbar.show(
                    ScreenSnackbar.loginscreen,
                    "Login Failed",
                    success: false,
                  );
                }

                /// handshake
                if (_value.length > 1) {
                  log("LENGTH HANDSHAKE : ${_value.length}");
                  valueHandshake = _value;
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
      Snackbar.show(
          ScreenSnackbar.loginscreen, prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  void _onTextChanged() {
    String text =
        idTxtController.text.replaceAll(":", ""); // Remove existing colons
    String formattedText = "";

    // Add colon after every 2 characters
    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        formattedText += ":";
      }
    }

    // Prevent unnecessary updates (cursor position fixes)
    if (formattedText != idTxtController.text) {
      final cursorPosition = idTxtController.selection.baseOffset;
      idTxtController.value = idTxtController.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(
            offset: cursorPosition +
                (formattedText.length - idTxtController.text.length)),
      );
    }
  }

  void initSubscription() {
    for (var service in _services) {
      // log("characteristic : ${service.characteristics}");
      for (var characteristic in service.characteristics) {
        // log("ini true kah : ${characteristic.properties.notify}");
        if (characteristic.properties.notify) {
          // await characteristic
          onSubscribePressed(characteristic);
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  Future onSubscribePressed(BluetoothCharacteristic c) async {
    log("masuk sini tak ?");
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      await c.setNotifyValue(true);
      // if (c.isNotifying) {
      //   initLastValueSubscription(_device);
      // }
      Snackbar.show(ScreenSnackbar.loginscreen, "$op : Success", success: true);
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

  /// SCAN FOR DEVICES
  void searchForDevices() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    bool isFound = false;

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        log("SCAN RESULT : ${result}");
        log("SCAN RESULT DEVICE : ${result.device}");
        if (result.device.remoteId.toString().toUpperCase() ==
            idTxtController.text.toUpperCase()) {
          FlutterBluePlus.stopScan(); // Stop scanning
          connectProcess(result.device);
          _scanResultsSubscription.cancel();
          isFound = true;
          break;
        }

        if (result.device.advName.toUpperCase() ==
            macAddressTxtConroller.text.toUpperCase()) {
          FlutterBluePlus.stopScan();
          connectProcess(result.device);
          _scanResultsSubscription.cancel();
          isFound = true;
          break;
        }
      }
    });

    if (isFound == false) {
      Snackbar.show(ScreenSnackbar.loginscreen, "Target Device Not Found",
          success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            // hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: userRoleTxtController,
                      decoration: const InputDecoration(
                        labelText: "User Role",
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                        10,
                      )),
                      color: indexPage == index ? Colors.blue : Colors.white,
                      child: Center(
                        child: Text(
                          pageListPumpDetail[index],
                          style: GoogleFonts.readexPro(
                            color:
                                indexPage != index ? Colors.blue : Colors.white,
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
                      TextFormField(
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
                          if (macAddressTxtConroller.text.isNotEmpty) {}
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
                  Column(
                    children: [
                      TextFormField(
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
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (idTxtController.text.isNotEmpty) {
                            // await _bleMainScreenController
                            //     .loginWithSearchId(idTxtController.text);
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
                  // login use scan
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScanScreenX(
                                userRole: userRoleTxtController.text,
                                password: passwordTxtController.text,
                              ),
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
          )
        ],
      ),
    );
  }
}
