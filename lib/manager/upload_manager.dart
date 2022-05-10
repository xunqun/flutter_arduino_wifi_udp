import 'dart:math';

import 'package:flutter_wifi_udp/command/out_command.dart';
import 'package:flutter_wifi_udp/manager/settings.dart';
import 'package:flutter_wifi_udp/manager/wifi_manager.dart';

import 'log_manager.dart';

var uploadManager = UploadManager();
class UploadManager {

  Future<bool> startTask(List<int> data, String fileExt) async {

    var startTime = DateTime.now();
    var segments = (data.length ~/ settings.dataLength);
    if (data.length % settings.dataLength > 0) {
      segments += 1;
    }
    var bytes = StartCommand(segments, fileExt).bytes;
    logManager.addSendRaw(bytes, msg: 'START COMMAND', desc: 'total chunks: $segments');
    var response = await udpManager.write(bytes);
    logManager.addReceiveRaw(response, msg: 'START ACK');
    for (int i = 0; i < segments; i++) {
      var start = settings.dataLength * i;
      var end = min(start + settings.dataLength, data.length);
      var dataSegment = data.sublist(start, end);
      bytes = DataCommand(dataSegment, i).bytes;
      logManager.addSendRaw(bytes, msg:'DATA COMMAND', desc: 'chunk $i');
      response = await udpManager.write(bytes);
      logManager.addReceiveRaw(response, msg: 'DATA ACK');
    }
    bytes = EndCommand().bytes;
    var ms = DateTime.now().difference(startTime).inMilliseconds;
    logManager.addSendRaw(bytes, msg: 'END COMMAND', desc: 'total cost $ms ms');
    response = await udpManager.write(bytes);
    logManager.addReceiveRaw(response, msg: 'END ACK');

    return true;
  }
}
