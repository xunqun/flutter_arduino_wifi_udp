import 'dart:convert';

import 'package:flutter_wifi_udp/manager/settings.dart';
import 'package:flutter_wifi_udp/utility/byte_tool.dart';

// class StartCommand {
//   List<int> begin = settings.beginByte;
//   List<int> end = settings.endByte;
//   List<int> word = ByteTool.stringToListIntWithSize(utf8.encode(settings.startWord), 8);
//   List<int> type = ByteTool.stringToListIntWithSize(utf8.encode('wav'), 5);
//   int length = 15;
//   int count = 0;
//
//
//   StartCommand(this.count, String fileExt) {
//     type = ByteTool.stringToListIntWithSize(utf8.encode(fileExt), 5);
//   }
//
//   int get checkSum => ByteTool.checkSum(word + type + ByteTool.int32bytes(count, 2));
//
//   get bytes => begin + ByteTool.int32bytes(length, 1) + word + type + ByteTool.int32bytes(count, 2) + ByteTool.int32bytes(checkSum, 1) + end;
// }
//
// class EndCommand {
//   List<int> begin = settings.beginByte;
//   List<int> end = settings.endByte;
//   int length = 8;
//   List<int> word = ByteTool.stringToListIntWithSize(utf8.encode(settings.endWord), 8);
//
//
//   EndCommand();
//
//   int get checkSum => ByteTool.checkSum(word);
//
//   get bytes => begin + ByteTool.int32bytes(length, 1) + word + ByteTool.int32bytes(checkSum, 1) + end;
// }
//
// class DataCommand {
//   List<int> begin = settings.beginByte;
//   List<int> end = settings.endByte;
//   int length = settings.dataLength;
//   List<int> raw;
//   int counter = 0;
//
//   DataCommand(this.raw, this.counter) {
//     length = raw.length + 2; // counter length = 2
//   }
//
//   int get checkSum => ByteTool.checkSum(raw + ByteTool.int32bytes(counter, 2));
//
//   get bytes => begin + ByteTool.int32bytes(length, 1) + raw + ByteTool.int32bytes(counter, 2) + ByteTool.int32bytes(checkSum, 1) + end;
// }

abstract class OutCommanad{
  List<int> get bytes;
  String get string;
}

/**
 * SetVolume=15;
 */
class SetVolumeCommand extends OutCommanad{
  int volume;
  SetVolumeCommand(this.volume);
  @override
  get bytes => utf8.encode(string);
  @override
  get string => 'Volume=$volume\r\n';
}

class AskVolumeCommand extends OutCommanad{
  @override
  get bytes => utf8.encode(string);
  @override
  get string => 'Volume?\r\n';
}

/**
 * SetBlinkTime=700;
 */
class SetBlinkTimeCommand extends OutCommanad{
  int blink; //(單位 ms, 預設600)
  SetBlinkTimeCommand(this.blink);
  @override
  get bytes => utf8.encode(string);
  @override
  get string => 'BlinkTime=$blink\r\n';
}

class AskBlinkTime extends OutCommanad{
  @override
  get bytes => utf8.encode(string);
  @override
  get string => 'BlinkTime?\r\n';
}

/**
 * SetBootSound=1;
 */
class SetBootSoundCommand extends OutCommanad{
  bool enable;
  String path; // (0:關閉開機音效; 1:開啟開機音效)
  SetBootSoundCommand(this.enable, this.path);
  get bytes => utf8.encode(string);
  get string => 'BootSound=${enable ? 1 : 0},\"/r/$path\"\r\n';
}

class AskBootSoundCommnad extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'BootSound?\r\n';
}

/**
 * SetBlinkSoundMode=1;
 */
class SetBlinkSoundCommand extends OutCommanad{
  bool enable; // (0:原廠音效,無法調音量及時間; 1:使用者自訂)
  String path;
  SetBlinkSoundCommand(this.enable, this.path);
  get bytes => utf8.encode(string);
  get string => 'BlinkSound=${enable ? 1 : 0},\"/r/$path\"\r\n';
}

class AskBlinkSoundCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'BlinkSound?\r\n';
}

/**
 * BLE name
 */
class SetBleNameCommand extends OutCommanad{
  String name;
  SetBleNameCommand(this.name);
  get bytes => utf8.encode(string);
  get string => 'BLEName=\"$name\"\r\n';
}

class AskBleNameCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'BLEName?\r\n';
}

/**
 * Wifi SSID
 */
class SetWifiSsidCommand extends OutCommanad{
  String name;
  SetWifiSsidCommand(this.name);
  get bytes => utf8.encode(string);
  get string => 'WiFiSSID=\"$name\"\r\n';
}

class AskWifiSsidCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => ' \r\nWiFiSSID?\r\n';
}

/**
 * Wifi Password
 */
class SetWifiPwCommand extends OutCommanad{
  String pw;
  SetWifiPwCommand(this.pw);
  get bytes => utf8.encode(string);
  get string => 'WiFiPwd=\"ABCD1234\"\r\n';
}

class AskWifiPwCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'WiFiPwd?\r\n';
}

/**
 * Wifi status
 */
class SetWifiStatusCommand extends OutCommanad{
  bool enable;
  SetWifiStatusCommand(this.enable);
  get bytes => utf8.encode(string);
  get string => 'WiFiStatus=1\r\n';
}

/**
 * Play sound
 */
class SetPlaySoundCommand extends OutCommanad{
  String path;
  SetPlaySoundCommand(this.path);
  get bytes => utf8.encode(string);
  get string => 'PlaySound=\"/r/$path\"\r\n';
}

class SetStopSoundCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'StopSound\r\n';
}

/**
 * Factory reset
 */

class FactoryResetCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'FactorySetup\r\n';
}

class SetupSaveCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'SetupSave\r\n';
}

class SetLightErrorCommand extends OutCommanad{
  bool enable;
  SetLightErrorCommand(this.enable);
  get bytes => utf8.encode(string);
  get string => 'LightError=${enable?1:0}\r\n';
}

class AskLightErrorCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'LightError?\r\n';
}

class AskLightLearningCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'LightLearning\r\n';
}

class AskBleUnboundCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'BLEUnbond\r\n';
}

class AskFlashSizeCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => 'FlashSize?\r\n';
}

class AskVersionCommand extends OutCommanad{
  get bytes => utf8.encode(string);
  get string => ' \r\nVersion?\r\n';
}

// /**
//  * SetLightLoad=550;
//  */
// class LightLoadCommand{
//   int value; //(預設550)
//   LightLoadCommand(this.value);
//   get bytes => utf8.encode(string);
//   get string => 'SetLightLoad=$value;';
// }
//
// /**
//  * SetWiFiSSID="Koso flasher";
//  * 16進制 : 53 65 74 57 69 46 69 53 53 49 44 3d 22 4b 6f 73 6f 20 46 6c 61 73 68 65 72 22 3b
//  */
// class WifiSsidCommand{
//   String value; //(長度最多 32 Byte)
//   WifiSsidCommand(this.value);
//   get bytes => utf8.encode(string);
//   get string => 'SetWiFiSSID=$value;';
// }
//
//
// /**
//  * SetWiFiPwd="ABCD1234";
//  * 16進制 : 53 65 74 57 69 46 69 50 77 64 3d 22 41 42 43 44 31 32 33 34 22 3b
//  */
// class WifiPwdCommand{
//   String value; //(長度最多 30 Byte)
//   WifiPwdCommand(this.value);
//   get bytes => utf8.encode(string);
//   get string => 'SetWiFiPwd=$value;';
// }
//
// /**
//  * BlinkSound="/Test.mp3";
//  * 16進制 : 42 6c 69 6e 6b 53 6f 75 6e 64 3d 22 2f 54 65 73 74 2e 6d 70 33 22 3b
//  */
// class BlinkSoundCommand{
//   String name; //(長度最多 30 Byte)
//   bool enable;
//   BlinkSoundCommand(this.enable, this.name);
//   get bytes => utf8.encode(string);
//   get string => 'BlinkSound=${enable ? 1 : 0},\"/r/$name\"\r\n';
// }
//
// /**
//  * BootSound="/Test.mp3";
//  * 16進制 : 42 6f 6f 74 53 6f 75 6e 64 3d 22 2f 54 65 73 74 2e 6d 70 33 22 3b
//  */
// class BootSoundCommand{
//   String value; //(長度最多 30 Byte)
//   BootSoundCommand(this.value);
//   get bytes => utf8.encode(string);
//   get string => 'BlinkSound=$value;';
// }
//
// /**
//  * 全部回復原廠設定
//  * FactorySetup;
//  * 16進制 : 46 61 63 74 6f 72 79 53 65 74 75 70 3b
//  */
// class FactoryRecoveryCommand{
//   FactoryRecoveryCommand();
//   get bytes => utf8.encode(string);
//   get string => 'FactorySetup;';
// }
//
