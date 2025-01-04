import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/utils/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/snackbar.dart';

class SetPasswordScreen extends StatefulWidget {
  final BluetoothDevice device;

  const SetPasswordScreen({super.key, required this.device});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];

  TextEditingController pwdNewTxtController = TextEditingController();
  TextEditingController pwdNewConfirmTxtController = TextEditingController();
  TextEditingController pwdOldTxtController = TextEditingController();

  bool isSetPasswordScreen = true;
  bool isSetPasswordStart = false;

  bool isObscureTextOldPassword = true;
  bool isObsecureTextNewPasssword = true;
  bool isObsecureTextConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (_connectionState == BluetoothConnectionState.disconnected) {
        // Navigator.pop(context);
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      if (mounted) {
        setState(() {});
      }
    });
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isSetPasswordScreen = false;
    super.dispose();
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 1));
    if (isConnected) {
      try {
        _services = await device.discoverServices();
        initLastValueSubscription(device);
      } catch (e) {
        Snackbar.show(ScreenSnackbar.setpassword,
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
              if (characters.properties.notify && isSetPasswordScreen) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");
                if (isSetPasswordStart) {
                  if (_value.length == 1 && _value[0] == 1) {
                    Snackbar.show(
                        ScreenSnackbar.setpassword, "Success Set New Passoword",
                        success: true);
                  } else {
                    Snackbar.show(
                        ScreenSnackbar.setpassword, "Fail Set New Passoword",
                        success: false);
                  }
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
          ScreenSnackbar.setpassword, prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarSetPassword,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Set Password"),
          elevation: 0,
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
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
                        obscureText: isObscureTextOldPassword,
                        controller: pwdOldTxtController,
                        decoration: InputDecoration(
                          labelText: "Old Password",
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isObscureTextOldPassword =
                                    !isObscureTextOldPassword;
                              });
                            },
                            child: Icon(
                              isObscureTextOldPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        style: GoogleFonts.readexPro(),
                        obscureText: isObsecureTextNewPasssword,
                        cursorColor: Colors.transparent,
                        controller: pwdNewTxtController,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isObsecureTextNewPasssword =
                                    !isObsecureTextNewPasssword;
                              });
                            },
                            child: Icon(
                              isObsecureTextNewPasssword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        style: GoogleFonts.readexPro(),
                        obscureText: isObsecureTextConfirmPassword,
                        cursorColor: Colors.transparent,
                        controller: pwdNewConfirmTxtController,
                        decoration: InputDecoration(
                          labelText: "Confirm New Password",
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isObsecureTextConfirmPassword =
                                    !isObsecureTextConfirmPassword;
                              });
                            },
                            child: Icon(
                              isObsecureTextConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (pwdOldTxtController.text.isEmpty ||
                              pwdNewTxtController.text.isEmpty ||
                              pwdNewConfirmTxtController.text.isEmpty) {
                            Snackbar.show(ScreenSnackbar.setpassword,
                                "Password cannot be empty",
                                success: false);
                            return;
                          } else {
                            if (pwdNewTxtController.text !=
                                pwdNewConfirmTxtController.text) {
                              Snackbar.show(ScreenSnackbar.setpassword,
                                  "New Password not match",
                                  success: false);
                              return;
                            } else {
                              isSetPasswordStart = true;
                              List<int> list = utf8.encode(
                                  "set_password=${pwdOldTxtController.text};${pwdNewTxtController.text}");
                              Uint8List bytes = Uint8List.fromList(list);
                              BLEUtils.funcWrite(
                                bytes,
                                "Set Password Command Success",
                                device,
                              );
                            }
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
                                "Set Password",
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
