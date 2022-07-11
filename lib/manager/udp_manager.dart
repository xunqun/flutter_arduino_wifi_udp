import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wifi_udp/command/incommand.dart';
import 'package:flutter_wifi_udp/manager/log_manager.dart';

UdpManager udpManager = UdpManager();

class UdpManager extends ChangeNotifier {
  /// Target AP connect state
  bool _isConnected = true;
  int _progress = 0;

  set progress(value) {
    if (_progress != value) {
      _progress = value;
      notifyListeners();
    }
  }

  get progress => _progress;

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
    _rawDatagramSocket?.writeEventsEnabled = true;
    _rawDatagramSocket?.listen((event) {
      switch (event) {
        case RawSocketEvent.read:
          Datagram? dg = _rawDatagramSocket?.receive();
          if (dg != null) {
            List<int> bytes = dg.data.toList();

            var ack = AckCommand.create(bytes);
            if (ack == null) {
              // logManager.addReceiveRaw(bytes);
            } else {
              logManager.addReceiveRaw(bytes, msg: "ACK");
            }
          }

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
    rawDatagramSocket?.send(data, InternetAddress('192.168.4.255'), 1234);
  }

  close() {
    rawDatagramSocket?.close();
  }
}
