import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_mcumgr/flutter_mcu_manager.dart';

import 'echo_box.dart';
import 'log_box.dart';
import 'upgrade_box.dart';
import 'upload_box.dart';

class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceDetailScreen({this.device}) {
    // this.device.connect();
  }

  @override
  _DeviceDetailScreenState createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  int _selectedIndex = 0;

  final List<Widget> _navBarWidgets = <Widget>[];

  final List<BottomNavigationBarItem> _navBarItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
        icon: Icon(Icons.device_hub), title: Text('Device')),
    BottomNavigationBarItem(
        icon: Icon(Icons.file_upload), title: Text('Image')),
    BottomNavigationBarItem(
        icon: Icon(Icons.file_upload), title: Text('Upgrade')),
    BottomNavigationBarItem(icon: Icon(Icons.folder), title: Text('Files')),
  ];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _navBarWidgets.addAll([
      EchoBox(device: widget.device),
      UploadBox(device: widget.device),
      UpgradeBox(device: widget.device),
      FilesBox(device: widget.device),
    ]);
  }

  Future<void> initPlatformState() async {
    try {
      FlutterMcuManager.connect(widget.device.id.id);
    } on PlatformException {}

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CupertinoColors.darkBackgroundGray,
        title:
            Text(widget.device.name.isEmpty ? 'Unknown' : widget.device.name),
        actions: [],
      ),
      body: Column(
        children: <Widget>[
          _deviceDetailCard(),
          _connectButton(),
          SizedBox(height: 20),
          Expanded(child: _navBarWidgets.elementAt(_selectedIndex)),
          // SizedBox(height: 10),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _navBarItems,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _deviceDetailCard() {
    return StreamBuilder<BluetoothDeviceState>(
      stream: widget.device.state,
      initialData: BluetoothDeviceState.connecting,
      builder: (c, snapshot) => Padding(
        padding: const EdgeInsets.all(10.0),
        child: Card(
          child: ListTile(
            leading: (snapshot.data == BluetoothDeviceState.connected)
                ? Icon(Icons.bluetooth_connected)
                : Icon(Icons.bluetooth_disabled),
            title: Text('Device is ${snapshot.data.toString().split('.')[1]}.'),
            subtitle: Text('${widget.device.id}'),
          ),
        ),
      ),
    );
  }

  Widget _connectButton() {
    return StreamBuilder<BluetoothDeviceState>(
      stream: widget.device.state,
      initialData: BluetoothDeviceState.connecting,
      builder: (context, snapshot) => RaisedButton(
          child: Visibility(
            visible: snapshot.data == BluetoothDeviceState.connected ||
                snapshot.data == BluetoothDeviceState.disconnected,
            child: Text(snapshot.data == BluetoothDeviceState.connected
                ? 'Disconnect'
                : 'Connect'),
            replacement: CupertinoActivityIndicator(),
          ),
          onPressed: () {
            switch (snapshot.data) {
              case BluetoothDeviceState.connected:
                widget.device.disconnect();
                break;
              case BluetoothDeviceState.disconnected:
                widget.device.connect();
                break;
              default:
                break;
            }
          }),
    );
  }
}
