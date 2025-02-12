import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_radio_checker.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RadioTestAsTransmit extends StatefulWidget {
  const RadioTestAsTransmit({super.key});

  @override
  State<RadioTestAsTransmit> createState() => _RadioTestAsTransmitState();
}

class _RadioTestAsTransmitState extends State<RadioTestAsTransmit> {
  late BLEProvider bleProvider;
  List<String> resultList = [];
  bool isTransmitStart = false;
  int intervalMs = 500;
  int repeat = 16;

  // text controller
  TextEditingController idTxtController = TextEditingController();
  TextEditingController intervalTxtController = TextEditingController();
  TextEditingController repeatTxtController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    idTxtController.text = "00:00:00:00:00";
    intervalTxtController.text = intervalMs.toString();
    repeatTxtController.text = repeat.toString();
    idTxtController.addListener(() {
      _onTextChanged(idTxtController);
    });
  }

  void _onTextChanged(TextEditingController textEditingController) {
    // Step 1: Remove invalid characters (allow only a-f, A-F, and 0-9)
    String text =
        textEditingController.text.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');

    // Step 2: Format the text with colons
    String formattedText = "";

    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        formattedText += ":";
      }
    }

    // Step 3: Prevent unnecessary updates and fix cursor position
    if (formattedText != textEditingController.text) {
      final cursorPosition = textEditingController.selection.baseOffset;
      textEditingController.value = textEditingController.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(
            offset: cursorPosition +
                (formattedText.length - textEditingController.text.length)),
      );
    }
  }

  Future<void> radioTransmitStop() async {
    isTransmitStart = false;
    BLEResponse resBLE =
        await CommandRadioChecker().radioTestAsTransmitterStop(bleProvider);
    if (!resBLE.status) {
      Snackbar.show(ScreenSnackbar.testradiotransmitscreen, resBLE.message,
          success: false);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyTestRadioTransmitScreen,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tes Radio sebagai Pengirim'),
          elevation: 0,
        ),
        body: Center(
            child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10))),
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            "Hasil Tes Radio sebagai Pengirim",
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                        //hasilnya
                        for (int i = 0; i < resultList.length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Row(
                              children: [
                                Text(
                                  resultList[i],
                                  style: const TextStyle(),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: idTxtController,
                          decoration: const InputDecoration(
                            labelText: "ID Toppi",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tolong diisi sebuah data';
                            }
                            return null;
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(14),
                            // FilteringTextInputFormatter
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        TextFormField(
                            controller: intervalTxtController,
                            decoration: const InputDecoration(
                              labelText: "Interval",
                              hintText: "500",
                              suffixText: "ms",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tolong diisi sebuah data';
                              }
                            }),
                        const SizedBox(
                          height: 8,
                        ),
                        TextFormField(
                          controller: repeatTxtController,
                          decoration: const InputDecoration(
                            labelText: "Repeat",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tolong diisi sebuah data';
                            }
                            return null;
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: MediaQuery.of(context).size.width,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (idTxtController.text.isEmpty) {
                                Snackbar.show(
                                    ScreenSnackbar.testradiotransmitscreen,
                                    "ID Toppi kosong",
                                    success: false);
                                return;
                              }
                              if (idTxtController.text.length != 14) {
                                Snackbar.show(
                                    ScreenSnackbar.testradiotransmitscreen,
                                    "ID Toppi salah",
                                    success: false);
                                return;
                              }
                              if (intervalTxtController.text.isEmpty) {
                                Snackbar.show(
                                    ScreenSnackbar.testradiotransmitscreen,
                                    "Interval Kosong",
                                    success: false);
                                return;
                              }
                              if (repeatTxtController.text.isEmpty) {
                                Snackbar.show(
                                    ScreenSnackbar.testradiotransmitscreen,
                                    "Repeat Kosong",
                                    success: false);
                                return;
                              }
                              if (!isTransmitStart) {
                                resultList.clear();
                                // ini untuk start radio transmit
                                isTransmitStart = true;
                                BLEResponse resBLE = await CommandRadioChecker()
                                    .radioTestAsTransmitterStart(
                                  bleProvider,
                                  ConvertV2().stringHexAddressToArrayUint8(
                                    idTxtController.text,
                                    5,
                                  ),
                                );
                                if (!resBLE.status) {
                                  Snackbar.show(
                                    ScreenSnackbar.testradiotransmitscreen,
                                    resBLE.message,
                                    success: false,
                                  );
                                  return;
                                }

                                for (var i = 0; i < repeat; i++) {
                                  log("i : $i == repeat : $repeat");

                                  if (!isTransmitStart) {
                                    isTransmitStart = false;
                                    setState(() {});
                                    break;
                                  }
                                  BLEResponse resBLESeq =
                                      await CommandRadioChecker()
                                          .radioTestAsTransmitterSequence(
                                              bleProvider, i)
                                          .timeout(
                                            Duration(
                                              milliseconds: intervalMs,
                                            ),
                                            onTimeout: () => BLEResponse(
                                              status: false,
                                              message: "Waktu habis",
                                            ),
                                          );
                                  if (!resBLESeq.status) {
                                    DateTime timeNow = DateTime.now();
                                    String formattedDate =
                                        DateFormat("yyyy-MM-dd HH:mm:ss")
                                            .format(timeNow);
                                    resultList.add(
                                        "[$formattedDate] hasil tes radio ${i + 1} : timeout");
                                    setState(() {});
                                  } else {
                                    DateTime timeNow = DateTime.now();
                                    String formattedDate =
                                        DateFormat("yyyy-MM-dd HH:mm:ss")
                                            .format(timeNow);
                                    resultList.add(
                                        "[$formattedDate] hasil tes radio ${i + 1} : ${resBLESeq.message}");
                                    setState(() {});
                                  }

                                  // break jika sudah sampai batas
                                  if (i + 1 >= repeat) {
                                    await radioTransmitStop();
                                    break;
                                  }
                                  await Future.delayed(Duration(
                                      milliseconds: intervalMs + 10000));
                                }
                              } else {
                                // ini untuk stop
                                await radioTransmitStop();
                              }
                            },
                            child: Text(
                              isTransmitStart ? "Stop" : "Mulai",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        )),
      ),
    );
  }
}
