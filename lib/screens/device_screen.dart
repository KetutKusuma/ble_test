import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';
import '../utils/snackbar.dart';
import '../utils/extra.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;
  late BluetoothDevice device;
  final TextEditingController _textController = TextEditingController();
  StreamSubscription<List<int>>? stream_sub;
  String valueChar = "empty";
  late BluetoothCharacteristic lastCharacterist;

  @override
  void initState() {
    super.initState();
    device = widget.device;
    log("DEVICE : $device");

    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _mtuSubscription = device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription = device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
    // listenToDeviceTest(widget.device);
  }

  setValuenya(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    if (services.isEmpty) {
      log("No services found!");
      return;
    }

    BluetoothService lastservice = services.last;
    if (lastservice.characteristics.isEmpty) {
      log("No characteristics found in the last service!");
      return;
    }
    lastCharacterist = lastservice.characteristics.last;
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await device.connectAndUpdateStream();
      // listenToDeviceTest(device);
      Snackbar.show(ScreenSnackbar.device, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(
            ScreenSnackbar.device, prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.device, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.device, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.device, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.device, prettyException("Disconnect Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await device.discoverServices();
      Snackbar.show(ScreenSnackbar.device, "Discover Services: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.device, prettyException("Discover Services Error:", e),
          success: false);
      log(e.toString());
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await device.requestMtu(512, predelay: 0);
      Snackbar.show(ScreenSnackbar.device, "Request Mtu: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.device, prettyException("Change Mtu Error:", e),
          success: false);
      log(e.toString());
    }
  }

  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map((c) => _buildCharacteristicTile(c))
                .toList(),
          ),
        )
        .toList();
  }

  CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles:
          c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
    );
  }

  Widget buildSpinner(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${device.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          onPressed: onDiscoverServicesPressed,
          child: const Text("Get Services"),
        ),
        const IconButton(
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget buildMtuTile(BuildContext context) {
    return ListTile(
      title: const Text('MTU Size'),
      subtitle: Text('$_mtuSize bytes'),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 200.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Expanded(
              flex: 2,
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text("Edit MTU to 512 bytes")),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onRequestMtuPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      TextButton(
          onPressed: _isConnecting
              ? onCancelPressed
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          child: Text(
            _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: Colors.white),
          ))
    ]);
  }

  // void listenToDeviceTest(BluetoothDevice device) async {
  //   await device.connect();
  //   log("device is COnnected : ${!device.isConnected}");
  //   if (!device.isConnected) {
  //     log("DEVICE IS NOT CONNECTED");
  //   } else {
  //     List<BluetoothService> services = await device.discoverServices();

  //     for (BluetoothService service in services) {
  //       for (BluetoothCharacteristic characteristic
  //           in service.characteristics) {
  //         // Check if characteristic supports Notify (TX stream)
  //         if (characteristic.properties.notify) {
  //           log("Found TX characteristic: ${characteristic.uuid}");
  //           setState(() {
  //             // txCharacteristic = characteristic;
  //           });
  //           startTXStream(characteristic);
  //           break;
  //         }
  //       }
  //     }
  //   }
  // }

  // void startTXStream(BluetoothCharacteristic characteristic) async {
  //   await characteristic.setNotifyValue(true);
  //   log("TX Stream enabled, listening for data...");

  //   characteristic.lastValueStream.listen((data) {
  //     if (data.isNotEmpty) {
  //       // Convert received data (List<int>) to a readable string
  //       log("DATA : ${data}");
  //       String charCode = String.fromCharCodes(data);
  //       String receivedString = utf8.decode(data, allowMalformed: true);
  //       log("Received TX Data: $receivedString, $charCode");
  //       valueChar = receivedString;
  //       // setState(() {});
  //     } else {
  //       log("No data received.");
  //     }
  //   });
  // }

  // void showPopupForm(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Enter Data to Send"),
  //         content: Form(
  //           key: _formKey,
  //           child: TextFormField(
  //             controller: _textController,
  //             decoration: const InputDecoration(
  //               labelText: "Enter text",
  //               border: OutlineInputBorder(),
  //             ),
  //             validator: (value) {
  //               if (value == null || value.isEmpty) {
  //                 return "Field cannot be empty";
  //               }
  //               return null;
  //             },
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close popup
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               if (_formKey.currentState!.validate()) {
  //                 String textToSend = _textController.text;

  //                 // Write to BLE characteristic if available
  //                 try {
  //                   List<BluetoothService> services =
  //                       await device.discoverServices();
  //                   BluetoothService lastService = services.last;
  //                   BluetoothCharacteristic lastCharacteristic =
  //                       lastService.characteristics.last;

  //                   List<int> list = utf8.encode(textToSend);
  //                   Uint8List bytes = Uint8List.fromList(list);
  //                   setState(() {});
  //                   await lastCharacteristic.setNotifyValue(true);
  //                   await lastCharacteristic.write(bytes);

  //                   // Aktifkan Notify/Indicate untuk menerima data balasan
  //                   if (lastCharacteristic.properties.notify) {
  //                     await lastCharacteristic.setNotifyValue(true);
  //                     log("Listening for response...");

  //                     lastCharacteristic.lastValueStream.listen((value) {
  //                       // Pastikan data balasan bukan echo
  //                       if (value.isNotEmpty &&
  //                           value.toString() != textToSend.toString()) {
  //                         String responseString =
  //                             utf8.decode(value, allowMalformed: true);
  //                         log("Received response: $responseString");
  //                       } else {
  //                         log("Received echoed data, waiting for proper response...");
  //                       }
  //                     });
  //                   } else {
  //                     log("This characteristic does not support Notify/Indicate");
  //                   }

  //                   log("pesan terkirim : $bytes");
  //                   log("Data sent successfully!");
  //                 } catch (e) {
  //                   log("Error sending data: $e");
  //                   _textController.clear();
  //                 }

  //                 _textController.clear();

  //                 // Close popup after sending
  //                 Navigator.of(context).pop();
  //               }
  //             },
  //             child: const Text("Send"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyDevice,
      child: Scaffold(
        appBar: AppBar(
          title: Text(device.platformName),
          actions: [
            Row(children: [
              if (_isConnecting || _isDisconnecting) buildSpinner(context),
              TextButton(
                  onPressed: _isConnecting
                      ? onCancelPressed
                      : (isConnected ? onDisconnectPressed : onConnectPressed),
                  child: Text(
                    _isConnecting
                        ? "CANCEL"
                        : (isConnected ? "DISCONNECT" : "CONNECT"),
                    style: Theme.of(context)
                        .primaryTextTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white),
                  ))
            ])
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${device.remoteId}'),
              ),
              ListTile(
                leading: buildRssiTile(context),
                title: Text(
                    'Device is ${_connectionState.toString().split('.')[1]}.'),
                trailing: buildGetServices(context),
              ),
              buildMtuTile(context),
              ..._services
                  .map(
                    (s) => ServiceTile(
                      service: s,
                      characteristicTiles: s.characteristics
                          .map((c) => CharacteristicTile(
                                characteristic: c,
                                descriptorTiles: c.descriptors
                                    .map((d) => DescriptorTile(descriptor: d))
                                    .toList(),
                              ))
                          .toList(),
                    ),
                  )
                  .toList(),
              // Text("Value : $valueChar"),
              // IconButton(
              //   onPressed: () => showPopupForm(context),
              //   icon: const Icon(Icons.upload),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
