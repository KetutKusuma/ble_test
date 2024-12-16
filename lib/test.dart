import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  bool bluetoothState = false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FlutterBluePlus.adapterState,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            if (snapshot.data == BluetoothAdapterState.on) {
              bluetoothState = true;
            } else if (snapshot.data == BluetoothAdapterState.off) {
              bluetoothState = false;
            }
            return Container(
              height: 30,
              child: SwitchListTile(
                  activeColor: Color(0xFF015164),
                  activeTrackColor: Color(0xFF0291B5),
                  inactiveTrackColor: Colors.grey,
                  inactiveThumbColor: Colors.white,
                  selectedTileColor: Colors.red,
                  title: Text(
                    'Activate Bluetooth',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: bluetoothState,
                  onChanged: (bool value) {
                    setState(() {
                      bluetoothState = !bluetoothState;
                      if (value) {
                        FlutterBluePlus.turnOn();
                      } else {
                        FlutterBluePlus.turnOff();
                      }
                    });
                  }),
            );
          } else {
            return Container();
          }
        });
  }
}
