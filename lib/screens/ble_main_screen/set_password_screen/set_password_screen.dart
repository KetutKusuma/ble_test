import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/utils/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../utils/snackbar.dart';

class SetPasswordScreen extends StatefulWidget {
  final BluetoothDevice device;

  const SetPasswordScreen({super.key, required this.device});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  TextEditingController pwdNewTxtController = TextEditingController();
  TextEditingController pwdNewConfirmTxtController = TextEditingController();
  TextEditingController pwdOldTxtController = TextEditingController();

  bool isObscureTextOldPassword = true;
  bool isObsecureTextNewPasssword = true;
  bool isObsecureTextConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarSetPassword,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ubah Password"),
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
                          labelText: "Password Lama",
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
                          labelText: "Password Baru",
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
                          labelText: "Konfirmasi Password Baru",
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
                                "Ubah Password",
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
