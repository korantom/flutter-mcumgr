import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'bluetooth_off_screen.dart';
import 'find_device_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        backgroundColor: CupertinoColors.lightBackgroundGray,
        appBar: AppBar(
          backgroundColor: CupertinoColors.darkBackgroundGray,
          title: Text('Devices'),
          actions: <Widget>[_searchButton()],
        ),
        body: SafeArea(
          child: StreamBuilder<BluetoothState>(
            stream: FlutterBlue.instance.state,
            initialData: BluetoothState.unknown,
            builder: (context, snapshot) {
              final bluetoothState = snapshot.data;

              return bluetoothState == BluetoothState.on
                  ? FindDevicesScreen()
                  : BluetoothOffScreen(state: bluetoothState);
            },
          ),
        ),
      ),
    );
  }

  Widget _searchButton() {
    return StreamBuilder<bool>(
      stream: FlutterBlue.instance.isScanning,
      initialData: false,
      builder: (c, snapshot) {
        if (snapshot.data) {
          return IconButton(
            icon: Icon(Icons.bluetooth_searching),
            color: Colors.blue,
            onPressed: () => FlutterBlue.instance.stopScan(),
          );
        } else {
          return IconButton(
            icon: Icon(Icons.bluetooth_searching),
            onPressed: () =>
                FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
            //TODO: Duration as param or constant
          );
        }
      },
    );
  }
}
