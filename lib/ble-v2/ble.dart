import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

class LoginAs {
  static const none = 0;
  static const admin = 1;
  static const operator = 2;
  static const guest = 3;
  static const forgetPassword = 4;
}

class Response {
  final Header header;
  final List<int> buffer;

  Response(this.header, this.buffer);

  @override
  String toString() {
    // TODO: implement toString
    return "{$header}$buffer";
  }
}

class BLEProvider with ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();

  Stream<List<int>> get dataStream => _dataController.stream;
  int _mtu = 23; // Default MTU size

  final StreamController<List<int>> _valueController =
      StreamController<List<int>>.broadcast();

  Stream<List<int>> get valueStream =>
      _valueController.stream; // Expose stream for live data

  int get mtu => _mtu; // Getter for MTU size

  Future<void> connect(BluetoothDevice device) async {
    try {
      _device = device;
      await _device!.connect();

      // Request MTU 512 (max allowed)
      await _requestMtu(512);

      // Discover services
      List<BluetoothService> services = await _device!.discoverServices();

      // Find characteristic (adjust UUID)
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            log("apakah dapet properties notify ? ${characteristic.properties.notify} ; ${characteristic.uuid}");
            _notifyCharacteristic = characteristic;
            _listenToNotifications();
          }

          if (characteristic.properties.write) {
            log("apakah dapet properties write ? ${characteristic.properties.write} ; ${characteristic.uuid}");
            _writeCharacteristic = characteristic;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      log("Error when connect : $e");
    }
  }

  Future<void> _requestMtu(int requestedMtu) async {
    if (_device != null) {
      try {
        int newMtu = await _device!.requestMtu(requestedMtu);
        _mtu = newMtu;
        debugPrint("MTU changed to: $_mtu");
      } catch (e) {
        debugPrint("MTU request failed: $e");
      }
    }
  }

  Future<Response> writeData(List<int> data, Header headerBLE) async {
    if (_writeCharacteristic != null) {
      try {
        log("idata Data to write : $data");
        await _writeCharacteristic!.write(
          data,
        );
        // log("Data written: $data");
        // return [];
        return await _listenToNotificationss(_notifyCharacteristic!, headerBLE);
      } catch (e) {
        log("Write failed: $e");
        rethrow;
      }
    } else {
      log("Characteristic not found!");
      throw Exception("Characteristic not found!");
    }
  }

  _listenToNotifications() async {
    log("apakah notifiyCharacteristic is null ? ${_notifyCharacteristic == null}");
    await _notifyCharacteristic!.setNotifyValue(true);
    if (_notifyCharacteristic!.isNotifying) {
      log("ini notifying");
      log("is notifyig ga nih : ${_notifyCharacteristic!.isNotifying}");
      StreamSubscription<List<int>>? lastValue =
          _notifyCharacteristic!.lastValueStream.listen(
        (value) {
          log("value is : $value");
          _dataController.add(value);
        },
        cancelOnError: true,
      );

      lastValue.onData((value) {
        log("value is : $value");
        _dataController.add(value);
      });
    } else {
      log("ini tidak notifying");
    }
  }

  Future<Response> _listenToNotificationss(
      BluetoothCharacteristic characteristic, Header headerBLE,
      {Duration timeout = const Duration(seconds: 3)}) async {
    await characteristic.setNotifyValue(true);

    Completer<Response> completer = Completer<Response>();
    StreamSubscription<List<int>>? subscription;

    subscription = characteristic.lastValueStream.listen((value) {
      log("Received Value: $value");
      _valueController.add(value); // Send value to stream

      if (!completer.isCompleted) {
        completer.complete(
            onReceive(value, headerBLE)); // Complete with first received value
      }

      subscription?.cancel(); // Cancel after receiving first value
    });

    // Timeout mechanism
    return Future.any([
      completer.future,
      Future.delayed(timeout, () {
        subscription?.cancel(); // Cancel the listener on timeout
        throw TimeoutException(
            "Timeout: No response received in ${timeout.inSeconds} seconds.");
      }),
    ]);
  }

  Future<Response> onReceive(List<int> dataResponse, Header headerBLE) async {
    try {
      if (dataResponse.isEmpty) {
        return Response(headerBLE, []);
      }
      List<int> buffer = [];
      bool resParse = await MessageV2().parse(
        dataResponse,
        InitConfig.data().KEY,
        InitConfig.data().IV,
        buffer,
      );

      if (!resParse) {
        return Response(headerBLE, []);
      }

      Header headerRes = MessageV2().getHeader(buffer);
      log("header response : $headerRes");
      if (headerRes.uniqueID == headerBLE.uniqueID &&
          headerRes.command == headerBLE.command) {
        return Response(headerRes, buffer);
      } else {
        throw Exception("Header not match");
      }
    } catch (e) {
      log("Error catch on receive : $e");
      throw Exception("Error catch on receive : $e");
    }
  }

  @override
  void dispose() {
    _dataController.close();
    _device?.disconnect();
    super.dispose();
  }
}

class UniqueIDManager {
  int _uniqueID = 0;

  int getUniqueID() {
    DateTime now = DateTime.now();

    // Extract hour, minute, and second
    String hour = now.hour.toString().padLeft(2, '0'); // HH
    String minute = now.minute.toString().padLeft(2, '0');
    if (_uniqueID == 65535) {
      _uniqueID = 0;
    }

    int ran = math.Random().nextInt(9);
    String uniqueIDStr = "$hour$minute$ran";

    return int.parse(uniqueIDStr);
  }
}
