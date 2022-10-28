import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SetupOptions{
  static var instance = SetupOptions._();
  Map<String, dynamic>? options;

  final StreamController<Map<String, dynamic>?> _dataController = StreamController<Map<String, dynamic>?>.broadcast();
  StreamSink<Map<String, dynamic>?> get _dataSink => _dataController.sink;
  Stream<Map<String, dynamic>?> get dataStream => _dataController.stream;

  SetupOptions._(){
    _getFromPersist();
  }

  _getFromPersist(){
    SharedPreferences.getInstance().then((pref) {
      var json = pref.getString('setup.json');
      if (json != null && json.isNotEmpty) {
        options = jsonDecode(json);
        _dataSink.add(options);
      }
    });
  }

  _persist(){
    String json = jsonEncode(options);
    SharedPreferences.getInstance().then((pref) {
      pref.setString('setup.json', json);
    });
  }

  loadFromJson(String string){
    options = jsonDecode(string);
    _dataSink.add(options);
  }

  putValue(String name, dynamic value){
    options![name] = value;
    _dataSink.add(options);
    _persist();
  }

  dynamic getValue(String name) => options![name];
}