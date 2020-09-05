import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_mcumgr/flutter_mcu_manager.dart';

class EchoBox extends StatefulWidget {
  final BluetoothDevice device;

  const EchoBox({this.device});

  @override
  _EchoBoxState createState() => _EchoBoxState();
}

class _EchoBoxState extends State<EchoBox> {
  List<String> messages = ['default'];
  final ScrollController scrollController = ScrollController();
  final TextEditingController textEditingController =
      TextEditingController(text: 'Hello');

  @override
  Widget build(BuildContext context) {
    // return Placeholder();
    return Column(
      children: [
        _messageInput(),
        SizedBox(height: 20),
        _messageList(),
      ],
    );
  }

  void _echo(String macAddr, String message) async {
    String reply = "_";
    try {
      reply = await FlutterMcuManager.echo(macAddr, message);
    } on PlatformException {
      reply = 'Failed to get message';
    }

    setState(() {
      messages.add(reply);
      scrollController.animateTo(messages.length * 65.0,
          duration: Duration(seconds: 1), curve: Curves.ease);
    });
  }

  Widget _messageInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: TextField(
            controller: textEditingController,
          ),
        ),
        Flexible(
          child: RaisedButton(
            child: Text('Echo'),
            onPressed: () =>
                _echo(widget.device.id.id, textEditingController.value.text),
          ),
        ),
      ],
    );
  }

  Widget _messageList() {
    return Expanded(
      child: ListView.separated(
          controller: scrollController,
          itemBuilder: (c, i) => Container(
              color: CupertinoColors.lightBackgroundGray,
              child: ListTile(title: Text('$i: ${messages[i]}'))),
          separatorBuilder: (c, i) => Divider(),
          itemCount: messages.length),
    );
  }
}
