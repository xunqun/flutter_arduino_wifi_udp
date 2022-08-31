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

/**
 * SetVolume=15;
 * 16進制 : 53 65 74 56 6f 6c 75 6d 65 3d 31 35 3b
 */
class VolumeCommand{
  int volume;
  VolumeCommand(this.volume);
  get bytes => utf8.encode(string);
  get string => 'SetVolume=$volume;';
}

/**
 * SetBlinkTime=700;
 * 16進制 : 53 65 74 42 6c 69 6e 6b 54 69 6d 65 3d 37 30 30 3b
 */
class BlinkTimeCommand{
  int blink; //(單位 ms, 預設600)
  BlinkTimeCommand(this.blink);
  get bytes => utf8.encode(string);
  get string => 'SetBlinkTime=$blink;';
}

/**
 * SetBootSound=1;
 * 16進制 : 53 65 74 42 6f 6f 74 53 6f 75 6e 64 3d 31 3b
 */
class BootSoundEnableCommand{
  int boot; // (0:關閉開機音效; 1:開啟開機音效)
  BootSoundEnableCommand(this.boot);
  get bytes => utf8.encode(string);
  get string => 'SetBootSound=$boot;';
}

/**
 * SetBlinkSoundMode=1;
 * 16進制 : 53 65 74 42 6c 69 6e 6b 53 6f 75 6e 64 4d 6f 64 65 3d 31 3b
 */
class BlinkSoundModeCommand{
  int mode; // (0:原廠音效,無法調音量及時間; 1:使用者自訂)
  BlinkSoundModeCommand(this.mode);
  get bytes => utf8.encode(string);
  get string => 'SetBlinkSoundMode=$mode;';
}

/**
 * SetLightLoad=550;
 * 16進制 : 53 65 74 4c 69 67 68 74 4c 6f 61 64 3d 35 35 30 3b
 */
class LightLoadCommand{
  int value; //(預設550)
  LightLoadCommand(this.value);
  get bytes => utf8.encode(string);
  get string => 'SetLightLoad=$value;';
}

/**
 * SetWiFiSSID="Koso flasher";
 * 16進制 : 53 65 74 57 69 46 69 53 53 49 44 3d 22 4b 6f 73 6f 20 46 6c 61 73 68 65 72 22 3b
 */
class WifiSsidCommand{
  String value; //(長度最多 32 Byte)
  WifiSsidCommand(this.value);
  get bytes => utf8.encode(string);
  get string => 'SetWiFiSSID=$value;';
}


/**
 * SetWiFiPwd="ABCD1234";
 * 16進制 : 53 65 74 57 69 46 69 50 77 64 3d 22 41 42 43 44 31 32 33 34 22 3b
 */
class WifiPwdCommand{
  String value; //(長度最多 30 Byte)
  WifiPwdCommand(this.value);
  get bytes => utf8.encode(string);
  get string => 'SetWiFiPwd=$value;';
}

/**
 * BlinkSound="/Test.mp3";
 * 16進制 : 42 6c 69 6e 6b 53 6f 75 6e 64 3d 22 2f 54 65 73 74 2e 6d 70 33 22 3b
 */
class BlinkSoundCommand{
  String value; //(長度最多 30 Byte)
  BlinkSoundCommand(this.value);
  get bytes => utf8.encode(string);
  get string => 'BlinkSound=$value;';
}

/**
 * BootSound="/Test.mp3";
 * 16進制 : 42 6f 6f 74 53 6f 75 6e 64 3d 22 2f 54 65 73 74 2e 6d 70 33 22 3b
 */
class BootSoundCommand{
  String value; //(長度最多 30 Byte)
  BootSoundCommand(this.value);
  get bytes => utf8.encode(string);
  get string => 'BlinkSound=$value;';
}

/**
 * 全部回復原廠設定
 * FactorySetup;
 * 16進制 : 46 61 63 74 6f 72 79 53 65 74 75 70 3b
 */
class FactoryRecoveryCommand{
  FactoryRecoveryCommand();
  get bytes => utf8.encode(string);
  get string => 'FactorySetup;';
}

