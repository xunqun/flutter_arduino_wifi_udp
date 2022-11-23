import 'dart:convert';

import 'package:flutter_wifi_udp/manager/setup_options.dart';

abstract class InCommand{
  List<int>? bytes;

  static InCommand? factory(List<int> bytes, {bool persist = false}){
    String raw = utf8.decode(bytes).trim();
    print(raw);
    var array = raw.split('=');

    InCommand? cmd;
    switch(array[0]){
      case ReceivedVolume.tag:
        cmd = ReceivedVolume(int.parse(array[1]));
        if(persist) SetupOptions.instance.putVolume(int.parse(array[1]));
        break;
      case ReceivedBlinktime.tag:
        cmd = ReceivedBlinktime(int.parse(array[1]));
        if(persist) SetupOptions.instance.putBlinkInterval(int.parse(array[1]));
        break;
      case ReceivedBootSound.tag:
        cmd = ReceivedBootSound(array[1]);
        var items = array[1].split(',');
        if(persist && items.isNotEmpty){
          SetupOptions.instance.putEnableBootSound(int.parse(items[0]) == 1);
          if(items.length>1) {
            SetupOptions.instance.putBootSound(items[1].replaceAll('/r/', ''));
          }
        };
        break;
      case ReceivedBlinkSound.tag:
        cmd = ReceivedBlinkSound(array[1]);
        var items = array[1].split(',');
        if(persist && items.isNotEmpty){
          SetupOptions.instance.putEnableBlinkSound(int.parse(items[0]) == 1);
          if(items.length>1) {
            SetupOptions.instance.putBlinkSound(items[1].replaceAll('/r/', ''));
          }
        };
        break;
      case ReceivedBleName.tag:
        cmd = ReceivedBleName(array[1]);
        if(persist) SetupOptions.instance.putBleName(array[1]);
        break;
      case ReceivedWiFiSSID.tag:
        cmd = ReceivedWiFiSSID(array[1]);
        if(persist) SetupOptions.instance.putWifiSsid(array[1]);
        break;
      case ReceivedWiFiPwd.tag:
        cmd = ReceivedWiFiPwd(array[1]);
        if(persist) SetupOptions.instance.putWifiPw(array[1]);
        break;
      case ReceivedWiFiStatus.tag:
        cmd = ReceivedWiFiStatus(int.parse(array[1]));
        if(persist) SetupOptions.instance.putWifiStatus(int.parse(array[1]) == 1);
        break;
      case ReceivedLightError.tag:
        cmd = ReceivedLightError(int.parse(array[1]));
        if(persist) SetupOptions.instance.putLightError(int.parse(array[1]) == 1);
        break;
      case ReceivedFlashSize.tag:
        cmd = ReceivedFlashSize(array[1]);
        if(persist) SetupOptions.instance.putFlashSize(array[1]);
        break;
      case ReceivedVersion.tag:
        cmd = ReceivedVersion(array[1]);
        if(persist) SetupOptions.instance.putVersion(array[1]);
        break;
      case ResultOk.tag:
        cmd = ResultOk();
        break;
      case ResultError.tag:
        cmd = ResultError();
        break;
      case ReceivedWifiTimeout.tag:
        cmd = ReceivedWifiTimeout();
        break;
      default:
        cmd = null;
    }
    cmd?.bytes = bytes;
    return cmd;
  }


}

class ReceivedWifiTimeout extends InCommand{
  static const String tag = 'WiFi Timeout';
}

class ResultOk extends InCommand{
  static const String tag = 'OK';
}

class ResultError extends InCommand{
  static const String tag = 'Error';
}

class ReceivedVolume extends InCommand{
  static const String tag = 'Volume';
  int volume = 0;
  ReceivedVolume(this.volume);
}

class ReceivedBlinktime extends InCommand{
  static const String tag = 'BlinkTime';
  int value = 600;
  ReceivedBlinktime(this.value);
}

class ReceivedBootSound extends InCommand{
  static const String tag = 'BootSound';
  String value = '';
  ReceivedBootSound(this.value);
}

class ReceivedBlinkSound extends InCommand{
  static const String tag = 'BlinkSound';
  String value = '';
  ReceivedBlinkSound(this.value);
}

class ReceivedBleName extends InCommand{
  static const String tag = 'BLEName';
  String value = '';
  ReceivedBleName(this.value);
}

class ReceivedWiFiSSID extends InCommand{
  static const String tag = 'WiFiSSID';
  String value = '';
  ReceivedWiFiSSID(this.value);
}

class ReceivedWiFiPwd extends InCommand{
  static const String tag = 'WiFiPwd';
  String value = '';
  ReceivedWiFiPwd(this.value);
}

class ReceivedWiFiStatus extends InCommand{
  static const String tag = 'WiFiStatus';
  int value = 0;
  ReceivedWiFiStatus(this.value);
}

class ReceivedLightError extends InCommand{
  static const String tag = 'LightError';
  int value = 0;
  ReceivedLightError(this.value);
}

class ReceivedFlashSize extends InCommand{
  static const String tag = 'FlashSize';
  int total = 0;
  int spare = 0;
  ReceivedFlashSize(String value){
    var array = value.split(',');
    total = int.parse(array[0]);
    spare = int.parse(array[1]);
  }
}

class ReceivedVersion extends InCommand{
  static const String tag = 'Version';
  String value = '';
  ReceivedVersion(this.value);
}


class AckCommand{
  var complete = 0; // byte3, 0未完成接收,1完成接收
  var resendRequired = 0; // byte5, 0不需要重傳 1需要重傳
  var filetype = 0;
  var dlc = 0;
  var count = 0;
  var checksum = 0;
  var finished = 0;

  AckCommand(List<int> raw){
    complete = raw[3];
    resendRequired = raw[5];
    filetype = raw[6];
    dlc = raw[7];
    count = raw[8];
    checksum = raw[9];
    finished = raw[10];
  }

  static AckCommand? create(List<int> raw){

    if(raw.length != 14){
      return null;
    }

    if(raw[0] != 0xAA || raw[1] != 0xBB || raw[12] != 0xCC || raw[13] != 0xDD){
      return null;
    }

    return AckCommand(raw);
  }
}

class IsInitializationCommand{
  IsInitializationCommand();
  get bytes => utf8.encode(string);
  get string => 'IsInitialization?';
}

class SetupCommand{
  SetupCommand();
  static SetupCommand? create(List<int> raw){
    if(raw.length != 138){
      return null;
    }
  }
  get bytes => utf8.encode(string);
  get string => 'Setup?';
}

class FileCommand{
  FileCommand();
  get bytes => utf8.encode(string);
  get string => 'File?';
}