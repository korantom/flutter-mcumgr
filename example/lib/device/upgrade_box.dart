import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_mcumgr/flutter_mcu_manager.dart';

class UpgradeBox extends StatefulWidget {
  final BluetoothDevice device;

  const UpgradeBox({this.device});

  @override
  _UpgradeBoxState createState() => _UpgradeBoxState();
}

class _UpgradeBoxState extends State<UpgradeBox> {
  String filePath = null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _loadButton(),
          _uploadControlls(),
          _statusInfo(),
          _progressInfo(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

/* ------------------------------------------------------------------------ */

  void _load(String filePath) async {
    await FlutterMcuManager.load(filePath);
  }

  void _upload() async {
    await FlutterMcuManager.upgrade();
  }

  void _pause() async {
    await FlutterMcuManager.pauseUpgrade();
  }

  void _resume() async {
    await FlutterMcuManager.resumeUpgrade();
  }

  void _cancel() async {
    await FlutterMcuManager.cancelUpgrade();
  }

  Widget _loadButton() {
    return RaisedButton(
        child: Text('Load'),
        onPressed: () async {
          filePath = await FilePicker.getFilePath(
              type: FileType.custom, allowedExtensions: ['bin']);
          _load(filePath);
        });
  }

  Widget _uploadControlls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: RaisedButton(child: Text('Start'), onPressed: () => _upload()),
        ),
        Flexible(
          child: RaisedButton(child: Text('Pause'), onPressed: () => _pause()),
        ),
        Flexible(
          child:
              RaisedButton(child: Text('Resume'), onPressed: () => _resume()),
        ),
        Flexible(
          child:
              RaisedButton(child: Text('Cancel'), onPressed: () => _cancel()),
        ),
      ],
    );
  }

  Widget _statusInfo() {
    return StreamBuilder<String>(
      stream: FlutterMcuManager.upgradeStatusStream,
      initialData: 'None',
      builder: (c, snapshot) {
        return Text('status: ${snapshot.data}');
      },
    );
  }

  Widget _progressInfo() {
    return StreamBuilder<double>(
      stream: FlutterMcuManager.ugradeProgressStream,
      initialData: 0.0,
      builder: (c, snapshot) {
        return Text('progress: ${snapshot.data * 100}%');
      },
    );
  }
}
