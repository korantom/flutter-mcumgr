import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'device/device_detail_screen.dart';

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
      // TODO: display connected devices? -> singlechildScroll: Column: [streamBuilder, streamBuilder]
      child: StreamBuilder<List<ScanResult>>(
        stream: FlutterBlue.instance.scanResults,
        initialData: [],
        builder: (c, snapshot) {
          final scanResultList = snapshot.data;
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: scanResultList.length,
            itemBuilder: (BuildContext context, int index) {
              final scanResult = scanResultList[index];
              return ScanResultTileCard(
                  scanResult: scanResult,
                  onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) {
                          return DeviceDetailScreen(device: scanResult.device);
                        }),
                      ));
            },
            separatorBuilder: (BuildContext context, int index) => Divider(),
          );
        },
      ),
    );
  }
}

class ScanResultTileCard extends StatelessWidget {
  final ScanResult scanResult;
  final VoidCallback onTap;
  const ScanResultTileCard({@required this.scanResult, this.onTap});

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListTile(
            leading: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(Icons.bluetooth),
                SizedBox(
                  height: 10,
                ),
                Expanded(child: Text("RSSI: ${scanResult.rssi}")),
              ],
            ),
            title: Text(scanResult.device.name.isEmpty
                ? 'Unknow'
                : scanResult.device.name),
            subtitle: Text(scanResult.device.id.id),
            trailing: Icon(Icons.more_vert),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }
}
