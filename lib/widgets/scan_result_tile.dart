import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatefulWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap})
    : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState>
  _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.result.device.connectionState.listen((
      state,
    ) {
      _connectionState = state;
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

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  String getNiceManufacturerData(List<List<int>> data) {
    return data
        .map((val) => '${getNiceHexArray(val)}')
        .join(', ')
        .toUpperCase();
  }

  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries
        .map((v) => '${v.key}: ${getNiceHexArray(v.value)}')
        .join(', ')
        .toUpperCase();
  }

  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.result.device.platformName.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.result.device.platformName,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "remote ID : ${widget.result.device.remoteId.str}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    } else {
      return Text(widget.result.device.remoteId.str);
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      child: isConnected ? const Text('Buka') : const Text('Sambungkan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      onPressed: (widget.result.advertisementData.connectable)
          ? widget.onTap
          : null,
    );
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // log("resultnya : ${widget.result}");
    var adv = widget.result.advertisementData;
    // log("advnya : $adv");
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text("RSSI: ${widget.result.rssi}"),
      trailing: _buildConnectButton(context),
      children: <Widget>[
        if (adv.advName.isNotEmpty) _buildAdvRow(context, 'Name', adv.advName),
        if (adv.txPowerLevel != null)
          _buildAdvRow(context, 'Tx Power Level', '${adv.txPowerLevel}'),
        if ((adv.appearance ?? 0) > 0)
          _buildAdvRow(
            context,
            'Appearance',
            '0x${adv.appearance!.toRadixString(16)}',
          ),
        if (adv.msd.isNotEmpty)
          _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(adv.msd),
          ),
        if (adv.serviceUuids.isNotEmpty)
          _buildAdvRow(
            context,
            'Service UUIDs',
            getNiceServiceUuids(adv.serviceUuids),
          ),
        if (adv.serviceData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Service Data',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    adv.serviceData.entries
                        .map(
                          (v) =>
                              '${v.key}: ${'[${v.value.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'}',
                        )
                        .join(', ')
                        .toUpperCase(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.apply(color: Colors.black),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
