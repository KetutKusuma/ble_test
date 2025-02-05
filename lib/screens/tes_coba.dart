import 'dart:convert';
import 'dart:developer';

import 'package:ble_test/ble-v2/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../ble-v2/ble.dart';

class TesCaraBaru extends StatefulWidget {
  const TesCaraBaru({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<TesCaraBaru> createState() => _TesCaraBaruState();
}

class _TesCaraBaruState extends State<TesCaraBaru> {
  late BLEProvider bleProvider;

  @override
  void initState() {
    super.initState();
    // init ble provider
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    initGet();
  }

  initGet() async {
    await bleProvider.connect(widget.device);
    await Command().handshake(widget.device, bleProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
              widget.device.disconnect();
            }),
        title: const Text("Listen to BLE"),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Command().handshake(widget.device, bleProvider);
              },
              child: Text("Handshake"),
            ),
            StreamBuilder<List<int>>(
              stream: bleProvider.dataStream, // Get BLE data stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Waiting for data...");
                }
                if (snapshot.hasData) {
                  String result = String.fromCharCodes(snapshot.data!);
                  return Text(
                      "Received: $result, Length: ${snapshot.data!.length}, ",
                      style: const TextStyle(fontSize: 20));
                }
                return const Text("No Data", style: TextStyle(fontSize: 20));
              },
            ),
          ],
        ),
      ),
    );
  }
}
