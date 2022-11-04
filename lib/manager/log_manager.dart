import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/model/log.dart';

var logManager = LogManager();
class LogManager extends ChangeNotifier{
  final int _max_count = 100000;
  final Queue<Log> _queue = Queue();

  int get count => _queue.length;

  addEvent(String msg, {String desc = ''}){
    if(_queue.length >= _max_count){
      _queue.removeFirst();
    }
    _queue.add(Log(DateTime.now(), LogType.event, title: msg, description: desc));
    notifyListeners();
  }

  addSendRaw(List<int> raw, {String msg = '', String desc = ''}){
    if(_queue.length >= _max_count){
      _queue.removeFirst();
    }
    _queue.add(Log(DateTime.now(), LogType.sendraw, raw: raw, title: msg, description: desc));
    notifyListeners();
  }

  addReceiveRaw(List<int> raw, {String msg = '', String desc = ''}){
    if(_queue.length >= _max_count){
      _queue.removeFirst();
    }
    _queue.add(Log(DateTime.now(), LogType.receiveraw, raw: raw.toList(), title: msg, description: desc));
    notifyListeners();
  }

  clear() {
    _queue.clear();
    notifyListeners();
  }

  List<Log> get list => _queue.toList(growable: false);

}