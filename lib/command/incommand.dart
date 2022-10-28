import 'dart:convert';

abstract class InCommand{
  static InCommand? factory(List<int> bytes){
    String raw = utf8.decode(bytes).trim();
    var array = raw.split('=');
    switch(array[0]){
      case ReceivedVolume.tag:
        return ReceivedVolume(int.parse(array[1]));
      case ReceivedBlinktime.tag:
        return ReceivedBlinktime(int.parse(array[1]));
      case ReceivedBootSound.tag:
        return ReceivedBootSound(array[1]);
      case ReceivedBlinkSound.tag:
        return ReceivedBlinkSound(array[1]);
      case ReceivedBleName.tag:
        return ReceivedBleName(array[1]);
      case ReceivedWiFiSSID.tag:
        return ReceivedWiFiSSID(array[1]);
      case ReceivedWiFiPwd.tag:
        return ReceivedWiFiPwd(array[1]);
      case ReceivedWiFiStatus.tag:
        return ReceivedWiFiStatus(int.parse(array[1]));
      case ReceivedLightError.tag:
        return ReceivedLightError(int.parse(array[1]));
      case ReceivedFlashSize.tag:
        return ReceivedFlashSize(array[1]);
      case ReceivedVersion.tag:
        return ReceivedVersion(array[1]);
      default:
        return null;
    }
  }

}

class ReceivedVolume extends InCommand{
  static const String tag = 'Volumn';
  int volumn = 0;
  ReceivedVolume(this.volumn);
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