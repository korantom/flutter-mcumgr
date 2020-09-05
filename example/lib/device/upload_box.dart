import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_mcumgr/flutter_mcu_manager.dart';
import 'package:flutter_mcumgr/firmware_image.dart';

class UploadBox extends StatefulWidget {
  final BluetoothDevice device;

  const UploadBox({this.device});

  @override
  _UploadBoxState createState() => _UploadBoxState();
}

class _UploadBoxState extends State<UploadBox> {
  List<FirmwareImage> images = [];
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
          Divider(),
          _slotControlls(),
          _resetButton(),
          if (images.isEmpty) Text('No Image Found'),
          if (images.isNotEmpty)
            Column(
              children: images.map((i) => Text(i.toString())).toList(),
            ),
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
    await FlutterMcuManager.upload();
  }

  void _pause() async {
    await FlutterMcuManager.pauseUpload();
  }

  void _resume() async {
    await FlutterMcuManager.resumeUpload();
  }

  void _cancel() async {
    await FlutterMcuManager.cancelUpload();
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
      stream: FlutterMcuManager.uploadStatusStream,
      initialData: 'None',
      builder: (c, snapshot) {
        return Text('status: ${snapshot.data}');
      },
    );
  }

  Widget _progressInfo() {
    return StreamBuilder<double>(
      stream: FlutterMcuManager.uploadProgressStream,
      initialData: 0.0,
      builder: (c, snapshot) {
        return Text('progress: ${snapshot.data * 100}%');
      },
    );
  }
/* ------------------------------------------------------------------------ */

  void _read() async {
    List<FirmwareImage> images;
    images = await FlutterMcuManager.read();

    setState(() {
      this.images = images;
    });
  }

  void _confirm() async {
    await FlutterMcuManager.confirm(images.last.hash);
    _read();
  }

  void _reset() async {
    await FlutterMcuManager.reset();
  }

  void _erase() async {
    await FlutterMcuManager.erase();
    _read();
  }

  Widget _resetButton() {
    return RaisedButton(child: Text('Reset'), onPressed: () => _reset());
  }

  Widget _slotControlls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: RaisedButton(child: Text('Read'), onPressed: () => _read()),
        ),
        Flexible(
          child: RaisedButton(child: Text('Test'), onPressed: () {}),
        ),
        Flexible(
          child:
              RaisedButton(child: Text('Confirm'), onPressed: () => _confirm()),
        ),
        Flexible(
          child: RaisedButton(child: Text('Erase'), onPressed: () => _erase()),
        ),
      ],
    );
  }

/* ------------------------------------------------------------------------ */
}
