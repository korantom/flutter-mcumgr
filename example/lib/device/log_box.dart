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
  String fileContent = "File Content";
  String commandResult = "Command Result";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Send Command"),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () async {
              String res =
                  await FlutterMcuManager.sendTextCommand("SAVE_LAST_BOOT");
              setState(() {
                this.commandResult = res;
              });
            },
          ),
          Text(commandResult),
          Divider(),
          Text('Download'),
          Divider(),
          _fileTextField(),
          Divider(),
          Text(this.filePath),
          _progressInfo(),
          _statusInfo(),
          Text(fileContent),
        ],
      ),
    );
  }

/* ------------------------------------------------------------------------ */

  void _download(String filePath) async {
    String fileContent = await FlutterMcuManager.readFile(filePath);
    setState(() {
      this.fileContent = fileContent;
    });
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
      initialData: "_",
      builder: (c, snapshot) {
        return Text("status: ${snapshot.data}");
      },
    );
  }
}
