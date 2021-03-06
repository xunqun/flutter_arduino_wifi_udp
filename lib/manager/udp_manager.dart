import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wifi_udp/manager/log_manager.dart';

UdpManager udpManager = UdpManager();

class UdpManager extends ChangeNotifier {
  /// Target AP connect state
  bool _isConnected = true;

  set isConnected(value) {
    _isConnected = value;
    notifyListeners();
  }

  get isConnected => _isConnected;

  /// Socket of UDP connection
  RawDatagramSocket? _rawDatagramSocket = null;

  set rawDatagramSocket(socket) {
    _rawDatagramSocket?.close();
    _rawDatagramSocket = null;
    _rawDatagramSocket = socket;
    _rawDatagramSocket?.listen((event) {
      switch (event) {
        case RawSocketEvent.read:
          Datagram? dg = _rawDatagramSocket?.receive();
          if (dg != null) {
            List<int> bytes = dg.data.toList();
            logManager.addReceiveRaw(bytes);
          }
          _rawDatagramSocket?.writeEventsEnabled = true;
          break;
        case RawSocketEvent.write:
          break;
        case RawSocketEvent.closed:
          print('Client disconnected.');
          logManager.addEvent('Client disconnected.');
      }
    });
  }

  get rawDatagramSocket => _rawDatagramSocket;


  write(List<int> data) {
    rawDatagramSocket?.send(
        data, InternetAddress('192.168.4.255'), 1234);
  }

  close() {
    rawDatagramSocket?.close();
  }
}
