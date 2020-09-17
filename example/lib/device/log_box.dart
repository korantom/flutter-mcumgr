import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_mcumgr/flutter_mcu_manager.dart';

class FilesBox extends StatefulWidget {
  final BluetoothDevice device;

  const FilesBox({this.device});

  @override
  _FilesBoxState createState() => _FilesBoxState();
}

class _FilesBoxState extends State<FilesBox> {
  String mountPoint = '/storage';
  String filePath = '/storage/last_boot';
  final TextEditingController filePathController =
      TextEditingController(text: 'last_boot');

  String commandText = 'SAVE_LAST_BOOT';
  final TextEditingController commandTextController =
      TextEditingController(text: 'SAVE_LAST_BOOT');

  String fileContent = "_";
  String commandResult = "_";

  @override
  Widget build(BuildContext context) {
    // return Placeholder();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Send Command", style: Theme.of(context).textTheme.headline5),
          _commandTextField(),
          Text("response: ${this.commandResult}"),
          Divider(),
          SizedBox(height: 50),
          Text('Download File', style: Theme.of(context).textTheme.headline5),
          _fileTextField(),
          Text("path: ${this.filePath}"),
          _progressInfo(),
          _statusInfo(),
          Text("file content: ${this.fileContent}"),
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

/* ------------------------------------------------------------------------ */
  void _sendTextCommand(String command) async {
    String res = await FlutterMcuManager.sendTextCommand(command);
    setState(() {
      this.commandResult = res;
    });
  }

  Widget _commandTextField() {
    return Row(
      children: [
        Flexible(
          child: TextField(
            controller: commandTextController,
            onChanged: (value) => setState(() => this.commandText = value),
          ),
        ),
        IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () => _sendTextCommand(this.commandText))
      ],
    );
  }
}
