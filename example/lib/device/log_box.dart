import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_mcumgr/flutter_mcu_manager.dart';

class LogBox extends StatefulWidget {
  final BluetoothDevice device;

  const LogBox({this.device});

  @override
  _LogBoxState createState() => _LogBoxState();
}

class _LogBoxState extends State<LogBox> {
  String mountPoint = '/storage';
  String filePath = '/storage/last_boot';
  final TextEditingController filePathController =
      TextEditingController(text: 'last_boot');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Download'),
          Divider(),
          _fileTextField(),
          Divider(),
          Text(this.filePath),
          _progressInfo(),
          _statusInfo(),
        ],
      ),
    );
  }

/* ------------------------------------------------------------------------ */

  void _download(String filePath) async {
    await FlutterMcuManager.readFile(filePath);
  }

  void _setMountPoint(String mountPoint) {}

  Widget _loadButton() {
    return RaisedButton(
        child: Text('Load'),
        onPressed: () async {
          _download(filePath);
        });
  }

  Widget _fileTextField() {
    return Row(
      children: [
        Flexible(
          child: TextField(
            controller: filePathController,
            onChanged: (value) =>
                setState(() => this.filePath = '${this.mountPoint}/${value}'),
          ),
        ),
        IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () => _download(this.filePath))
      ],
    );
  }

  Widget _progressInfo() {
    return StreamBuilder<double>(
      stream: FlutterMcuManager.fileDownlaodProgressStream,
      initialData: 0.0,
      builder: (c, snapshot) {
        return Text('progress: ${snapshot.data * 100}%');
      },
    );
  }

  Widget _statusInfo() {
    return StreamBuilder<String>(
      stream: FlutterMcuManager.fileDownloadStatusStream,
      initialData: "status:",
      builder: (c, snapshot) {
        return Text("status: ${snapshot.data}");
      },
    );
  }
}
