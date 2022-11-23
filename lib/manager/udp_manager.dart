import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:koso_flasher/command/incommand.dart';
import 'package:koso_flasher/constant/state.dart';
import 'package:koso_flasher/manager/log_manager.dart';
import 'package:wifi_iot/wifi_iot.dart';

WifiManager wifiManager = WifiManager();

class WifiManager extends ChangeNotifier {
  /// Target AP connect state
  ///
  bool _isConnected = false;
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
  // RawDatagramSocket? _rawDatagramSocket = null;
  Socket? _socket = null;
  set socket(s){
    _socket = s;

  }

  // set rawDatagramSocket(socket) {
  //
  //   // _rawDatagramSocket?.close();
  //   // _rawDatagramSocket = null;
  //   _rawDatagramSocket = socket;
  //   _rawDatagramSocket?.writeEventsEnabled = true;
  //   _rawDatagramSocket?.readEventsEnabled = true;
  //   _rawDatagramSocket?.listen((event) {
  //     switch (event) {
  //       case RawSocketEvent.read:
  //         Datagram? dg = _rawDatagramSocket?.receive();
  //         if (dg != null) {
  //           List<int> bytes = dg.data.toList();
  //
  //           var ack = AckCommand.create(bytes);
  //           if (ack == null) {
  //             logManager.addReceiveRaw(bytes);
  //           } else {
  //             logManager.addReceiveRaw(bytes, msg: "ACK");
  //           }
  //         }
  //
  //         break;
  //       case RawSocketEvent.write:
  //
  //         break;
  //       case RawSocketEvent.closed:
  //         print('Client disconnected.');
  //         logManager.addEvent('Client disconnected.');
  //         udpManager.isConnected = false;
  //     }
  //   });
  // }

  // get rawDatagramSocket => _rawDatagramSocket;

  write(List<int> data) {
    // rawDatagramSocket?.broadcastEnabled = false;
    // rawDatagramSocket?.send(data, InternetAddress('192.168.4.1'), 1234);
    // _socket?.add(data);
    _socket?.write(data);
  }

  close() {
    // rawDatagramSocket?.close();
    _socket?.close();
    _socket = null;
    appState.setState(ConnectState.idle);
    WiFiForIoTPlugin.forceWifiUsage(false);
  }
}
