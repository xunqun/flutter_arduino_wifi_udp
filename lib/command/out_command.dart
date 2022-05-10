import 'dart:convert';

import 'package:flutter_wifi_udp/manager/settings.dart';
import 'package:flutter_wifi_udp/utility/byte_tool.dart';

class StartCommand {
  List<int> begin = settings.beginByte;
  List<int> end = settings.endByte;
  List<int> word = ByteTool.stringToListIntWithSize(utf8.encode(settings.startWord), 8);
  List<int> type = ByteTool.stringToListIntWithSize(utf8.encode('wav'), 5);
  int length = 15;
  int count = 0;


  StartCommand(this.count, String fileExt) {
    type = ByteTool.stringToListIntWithSize(utf8.encode(fileExt), 5);
  }

  int get checkSum => ByteTool.checkSum(word + type + ByteTool.int32bytes(count, 2));

  get bytes => begin + ByteTool.int32bytes(length, 1) + word + type + ByteTool.int32bytes(count, 2) + ByteTool.int32bytes(checkSum, 1) + end;
}

class EndCommand {
  List<int> begin = settings.beginByte;
  List<int> end = settings.endByte;
  int length = 8;
  List<int> word = ByteTool.stringToListIntWithSize(utf8.encode(settings.endWord), 8);


  EndCommand();

  int get checkSum => ByteTool.checkSum(word);

  get bytes => begin + ByteTool.int32bytes(length, 1) + word + ByteTool.int32bytes(checkSum, 1) + end;
}

class DataCommand {
  List<int> begin = settings.beginByte;
  List<int> end = settings.endByte;
  int length = settings.dataLength;
  List<int> raw;
  int counter = 0;

  DataCommand(this.raw, this.counter) {
    length = raw.length + 2; // counter length = 2
  }

  int get checkSum => ByteTool.checkSum(raw + ByteTool.int32bytes(counter, 2));

  get bytes => begin + ByteTool.int32bytes(length, 1) + raw + ByteTool.int32bytes(counter, 2) + ByteTool.int32bytes(checkSum, 1) + end;
}
