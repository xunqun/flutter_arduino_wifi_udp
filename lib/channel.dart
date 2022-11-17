import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';


var talkie = NativeChannel();

class NativeChannel {
  static const _channel = MethodChannel('com.koso/flasher');

// candidates (scan results) stream
  final StreamController<Map<String, dynamic>> _connectstateController = StreamController.broadcast();
  StreamSink<Map<String, dynamic>> get _connectstateSink => _connectstateController.sink;
  Stream<Map<String, dynamic>> get connectstateStream => _connectstateController.stream;

  NativeChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'connectstate':
          print('NativeChannel connectstate = ${call.arguments}');
          var json = call.arguments;
          Map<String, dynamic> map = jsonDecode(json);
          _connectstateSink.add(map);
          break;
      }
    });
  }
}
