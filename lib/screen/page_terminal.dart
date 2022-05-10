import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/manager/log_manager.dart';
import 'package:flutter_wifi_udp/manager/wifi_manager.dart';
import 'package:flutter_wifi_udp/model/log.dart';
import 'package:intl/intl.dart';
import 'package:provider/src/provider.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({Key? key}) : super(key: key);

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final DateFormat dateFormatter = DateFormat('hh:mm:ss.SSS');
  final ScrollController _controller = ScrollController();
  String? error = null;

  @override
  Widget build(BuildContext context) {
    var logMgr = context.watch<LogManager>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vertical_align_bottom),
            onPressed: () {
              scrollDown();
            },
          ),
          IconButton(
            icon: const Icon(Icons.vertical_align_top),
            onPressed: () {
              scrollTop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_connected),
            onPressed: () {
              udpManager.disconnect();
            },
          ),
          IconButton(
            icon: const Icon(Icons.restore_from_trash),
            onPressed: () {
              logManager.clear();
            },
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(child: ListView.builder(
                controller: _controller,
                itemCount: logMgr.count,
                itemBuilder: (c, index) {
                  var log = logMgr.list[index];
                  final String time = dateFormatter.format(log.time);
                  return ExpansionTile(
                    title: ListTile(
                      leading: Text(time),
                      title: getTitle(log),
                      subtitle: Text(log.description ?? ''),
                    ),
                    children: [getSubtitle(log)],
                  );
                })),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: TextField(
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: '輸入16位元串，偶數個值', errorText: error),
                onSubmitted: (s) {
                  if (s.length.isEven) {
                    List<int> data = [];
                    for (int i = 0; i < s.length; i += 2) {
                      data.add(int.parse(s.substring(i, i + 2), radix: 16));
                    }
                    logManager.addSendRaw(data, msg: 'RAW', desc: 'manual input');
                    udpManager.write(data);
                    error = null;
                  } else {
                    error = '須為16位元字串，偶數個值';
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget getSubtitle(Log log) {
    if (log.type == LogType.sendraw) {
      return Column(
        children: [
          Text('${log.raw!.length} bytes'),
          Text(
            log.raw == null ? '' : log.raw!.map((e) => e.toRadixString(16).toUpperCase()).toList().toString(),
            style: TextStyle(color: Colors.blue, fontSize: 14),
          ),
        ],
      );
    } else if (log.type == LogType.receiveraw) {
      return Column(
        children: [
          Text('${log.raw!.length} bytes'),
          Text(
            log.raw == null ? '' : log.raw!.map((e) => e.toRadixString(16)).toList().toString(),
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      );
    } else {
      return Text('', style: TextStyle(fontSize: 14));
    }
  }

  Widget getTitle(Log log) {
    if (log.type == LogType.sendraw) {
      return Text(
        log.title ?? '',
        style: TextStyle(fontSize: 14),
      );
    } else if (log.type == LogType.receiveraw) {
      return Text(
        log.title ?? '',
        style: TextStyle(fontSize: 14),
      );
    } else {
      return Text(log.title ?? '', style: TextStyle(fontSize: 14));
    }
  }

  void scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  void scrollTop(){
    _controller.jumpTo(0);
  }
}