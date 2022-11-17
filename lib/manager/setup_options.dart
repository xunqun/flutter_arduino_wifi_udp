import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SetupOptions {
  static var instance = SetupOptions._();
  Map<String, dynamic> options = {};

  final StreamController<Map<String, dynamic>?> _dataController = StreamController<Map<String, dynamic>?>.broadcast();

  StreamSink<Map<String, dynamic>?> get _dataSink => _dataController.sink;

  Stream<Map<String, dynamic>?> get dataStream => _dataController.stream;

  SetupOptions._() {
  }

  _getFromPersist() {
    SharedPreferences.getInstance().then((pref) {
      var json = pref.getString('setup.json');
      if (json != null && json.isNotEmpty) {
        options = jsonDecode(json);

      }else{
        options = {};
      }
      _dataSink.add(options);
    });
  }

  _persist() {
    String json = jsonEncode(options);
    SharedPreferences.getInstance().then((pref) {
      pref.setString('setup.json', json);
    });
  }

  loadFromJson(String string) {
    options = jsonDecode(string);
    _dataSink.add(options);
  }

  putValue(String name, dynamic value) {
    options[name] = value;
    _dataSink.add(options);
    _persist();
  }

  dynamic getValue(String name) => options?[name];

  void putVolume(int volumn) => putValue('Volume', volumn);

  void putBlinkInterval(int interval) => putValue('Blink_Time', interval);

  void putEnableBootSound(bool enable) => putValue('Boot_Sound_EN', enable ? 1 : 0);

  void putBootSound(String path) => putValue('Boot_Sound', path);

  void putEnableBlinkSound(bool enable) => putValue('Blink_Sound_Mode', enable ? 1 : 0);

  void putBlinkSound(String path) => putValue('Blink_Sound', path);

  void putWifiStatus(bool enable) => putValue('WiFi_Status', enable ? 1 : 0);

  void putWifiSsid(String wifiSsid) => putValue('WiFi_SSID', wifiSsid);
  String? getWifiSsid() => getValue('WiFi_SSID');

  void putWifiPw(String wifiPw) => putValue('WiFi_Password', wifiPw);

  void putBleName(String bleName) => putValue('BLE_Name', bleName);

  void putLightError(bool enable) => putValue('Light_Error_EN', enable ? 1 : 0);

  void putPlaySound(String playSound) => putValue('Play_Sound', playSound);

  void putFlashSize(String size) => putValue('Flash_Size', size);

  void putVersion(String version) => putValue('Version', version);
}
