import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  var withServices = [Guid("180f")];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<BluetoothDevice>>(
              stream:
                  Stream.periodic(const Duration(seconds: 10)).asyncMap((_) {
                return FlutterBluePlus.systemDevices(withServices);
              }),
              initialData: const [],
              builder: (c, snapshot) {
                print(
                  "mama : ${snapshot.data}",
                );
                snapshot.data.toString();
                return snapshot.data == null
                    ? Text("No Devices")
                    : Column(
                        children: snapshot.data!.map((d) {
                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  d.platformName,
                                  style: TextStyle(color: Color(0xFFEDEDED)),
                                ),
                                leading: Icon(
                                  Icons.devices,
                                  color: Color(0xFFEDEDED).withOpacity(0.3),
                                ),
                                trailing:
                                    StreamBuilder<BluetoothConnectionState>(
                                  stream: d.connectionState,
                                  initialData:
                                      BluetoothConnectionState.disconnected,
                                  builder: (c, snapshot) {
                                    bool con = snapshot.data ==
                                        BluetoothConnectionState.connected;
                                    return ElevatedButton(
                                      child: Text(
                                        'Connect',
                                        style: TextStyle(
                                            color: con
                                                ? Colors.green
                                                : Colors.red),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                  color: con
                                                      ? Colors.green
                                                      : Colors.red),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(8)))),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(SelectedDevice(d, 1));
                                      },
                                    );
                                  },
                                ),
                              ),
                              Divider()
                            ],
                          );
                        }).toList(),
                      );
              },
            ),
            StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (c, snapshot) {
                List<ScanResult> scanresults = snapshot.data!;
                List<ScanResult> templist = [];
                scanresults.forEach((element) {
                  if (element.device.platformName != "") {
                    templist.add(element);
                  }
                });

                return Container(
                  height: 700,
                  child: ListView.builder(
                      itemCount: templist.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                templist[index].device.platformName,
                                style: TextStyle(color: Color(0xFFEDEDED)),
                              ),
                              leading: Icon(
                                Icons.devices,
                                color: Color(0xFFEDEDED).withOpacity(0.3),
                              ),
                              trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          side: BorderSide(
                                              color: Colors.orange))),
                                  onPressed: () async {
                                    Navigator.of(context).pop(SelectedDevice(
                                        templist[index].device, 0));
                                  },
                                  child: Text(
                                    "Connect",
                                    style: TextStyle(color: Color(0xFFEDEDED)),
                                  )),
                            ),
                            Divider()
                          ],
                        );
                      }),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(
                Icons.stop,
                color: Colors.red,
              ),
              onPressed: () => FlutterBluePlus.stopScan(),
              backgroundColor: Color(0xFFEDEDED),
            );
          } else {
            return FloatingActionButton(
                child: Icon(
                  Icons.search,
                  color: Colors.blue.shade300,
                ),
                backgroundColor: Color(0xFFEDEDED),
                onPressed: () => FlutterBluePlus.startScan(
                    timeout: const Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class SelectedDevice {
  BluetoothDevice? device;
  int? state;

  SelectedDevice(this.device, this.state);
}
