import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developerDart;
import 'dart:typed_data';

import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import "../utils/snackbar.dart";

import "descriptor_tile.dart";

class CharacteristicTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;

  const CharacteristicTile(
      {Key? key, required this.characteristic, required this.descriptorTiles})
      : super(key: key);

  @override
  State<CharacteristicTile> createState() => _CharacteristicTileState();
}

class _CharacteristicTileState extends State<CharacteristicTile> {
  List<int> _value = [];
  String data = "";
  final TextEditingController _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();
    _lastValueSubscription =
        widget.characteristic.lastValueStream.listen((value) {
      developerDart.log("message : $value");
      _value = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _lastValueSubscription.cancel();
    super.dispose();
  }

  BluetoothCharacteristic get c => widget.characteristic;

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  Future onReadPressed() async {
    try {
      await c.read();
      Snackbar.show(ScreenSnackbar.device, "Read: Success", success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.device, prettyException("Read Error:", e),
          success: false);
      print(e);
    }
  }

  Future onWritePressed() async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Enter Data to Send"),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: "Enter text",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Field cannot be empty";
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close popup
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_textController.text.isNotEmpty) {
                    List<int> list = utf8.encode(_textController.text);
                    Uint8List bytes = Uint8List.fromList(list);
                    await c.write(bytes,
                        withoutResponse: c.properties.writeWithoutResponse);
                    Snackbar.show(ScreenSnackbar.device, "Write: Success",
                        success: true);
                    if (c.properties.read) {
                      await c.read();
                    }
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Send"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Snackbar.show(ScreenSnackbar.device, prettyException("Write Error:", e),
          success: false);
      print(e);
    }
  }

  Future onSubscribePressed() async {
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      await c.setNotifyValue(c.isNotifying == false);
      Snackbar.show(ScreenSnackbar.device, "$op : Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.device, prettyException("Subscribe Error:", e),
          success: false);
      print(e);
    }
  }

  Widget buildUuid(BuildContext context) {
    String uuid = '0x${widget.characteristic.uuid.str.toUpperCase()}';
    return Text(uuid, style: const TextStyle(fontSize: 13));
  }

  Widget buildValue(BuildContext context) {
    String data = utf8.decode(_value).toString();
    // String data = _value.toString();
    return Text(data, style: const TextStyle(fontSize: 13, color: Colors.grey));
  }

  Widget buildReadButton(BuildContext context) {
    return TextButton(
        child: const Text("Read"),
        onPressed: () async {
          await onReadPressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Widget buildWriteButton(BuildContext context) {
    bool withoutResp = widget.characteristic.properties.writeWithoutResponse;
    return TextButton(
        child: Text(withoutResp ? "WriteNoResp" : "Write"),
        onPressed: () async {
          await onWritePressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Widget buildSubscribeButton(BuildContext context) {
    bool isNotifying = widget.characteristic.isNotifying;
    return TextButton(
        child: Text(isNotifying ? "Unsubscribe" : "Subscribe"),
        onPressed: () async {
          await onSubscribePressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Widget buildButtonRow(BuildContext context) {
    bool read = widget.characteristic.properties.read;
    bool write = widget.characteristic.properties.write;
    bool notify = widget.characteristic.properties.notify;
    bool indicate = widget.characteristic.properties.indicate;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (read)
          TextButton(
              child: const Text("Read"),
              onPressed: () async {
                await onReadPressed();
                if (mounted) {
                  setState(() {});
                }
              }),
        if (write)
          (BuildContext context) {
            bool withoutResp =
                widget.characteristic.properties.writeWithoutResponse;
            return TextButton(
                child: Text(withoutResp ? "WriteNoResp" : "Write"),
                onPressed: () async {
                  await onWritePressed();
                  if (mounted) {
                    setState(() {});
                  }
                });
          }(context),
        if (notify || indicate)
          (BuildContext context) {
            bool isNotifying = widget.characteristic.isNotifying;
            return TextButton(
                child: Text(isNotifying ? "Unsubscribe" : "Subscribe"),
                onPressed: () async {
                  await onSubscribePressed();
                  if (mounted) {
                    setState(() {});
                  }
                });
          }(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // developerDart.log("CHARACTERISTIC : ${widget.characteristic}");
    bool isNotifying = widget.characteristic.isNotifying;

    return ExpansionTile(
      title: ListTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            (widget.characteristic.properties.write)
                ? const Text('RX Characteristic')
                : (widget.characteristic.properties.notify)
                    ? const Text('TX Characteristic')
                    : const Text("Characteristic"),
            (BuildContext context) {
              String uuid = '0x${widget.characteristic.uuid.str}';
              return Text("UUID : $uuid", style: const TextStyle(fontSize: 13));
            }(context),
            (BuildContext context) {
              developerDart.log(
                "VALUE : $_value, ${widget.characteristic.properties.notify}, ${_value.isNotEmpty}",
              );

              if (widget.characteristic.properties.notify &&
                  _value.isNotEmpty) {
                developerDart.log("MASOK GA SINI");
                // int int16s = BytesConvert.bytesToInt32(_value);
                // developerDart.log("INT32S : $int16s");
              }
              String data = utf8.decode(_value).toString();
              // String data = _value.toString();

              return (data.isNotEmpty)
                  ? (widget.characteristic.properties.notify && !isNotifying
                      ? const SizedBox()
                      : Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text("Value : $data",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                        ))
                  : const SizedBox();
            }(context),
          ],
        ),
        subtitle: (BuildContext context) {
          bool read = widget.characteristic.properties.read;
          bool write = widget.characteristic.properties.write;
          bool notify = widget.characteristic.properties.notify;
          bool indicate = widget.characteristic.properties.indicate;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (read)
                TextButton(
                    child: const Text("Read"),
                    onPressed: () async {
                      await onReadPressed();
                      if (mounted) {
                        setState(() {});
                      }
                    }),
              if (write)
                (BuildContext context) {
                  bool withoutResp =
                      widget.characteristic.properties.writeWithoutResponse;
                  return TextButton(
                      child: Text(withoutResp ? "WriteNoResp" : "Write"),
                      onPressed: () async {
                        await onWritePressed();
                        if (mounted) {
                          setState(() {});
                        }
                      });
                }(context),
              if (notify || indicate)
                (BuildContext context) {
                  bool isNotifying = widget.characteristic.isNotifying;
                  return TextButton(
                      child: Text(isNotifying ? "Unsubscribe" : "Subscribe"),
                      onPressed: () async {
                        await onSubscribePressed();
                        if (mounted) {
                          setState(() {});
                        }
                      });
                }(context),
            ],
          );
        }(context),
        contentPadding: const EdgeInsets.all(0.0),
      ),
      children: widget.descriptorTiles,
    );
  }
}
