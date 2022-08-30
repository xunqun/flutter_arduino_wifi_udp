import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/constant/state.dart';
import 'package:flutter_wifi_udp/manager/udp_manager.dart';
import 'package:flutter_wifi_udp/screen/screen_screen.dart';
import 'package:provider/src/provider.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController ssidController = TextEditingController(text: 'HiAp');
  final TextEditingController pwController = TextEditingController(text: 'BB9ESERVER');
  String statusDescription = "未連線";

  @override
  Widget build(BuildContext context) {
    var udpManager = context.watch<UdpManager>();
    return StreamBuilder<ConnectState>(
        stream: state.connectStateStream,
        initialData: ConnectState.idle,
        builder: (context, snapshot) {
          statusDescription = getStatusDescription(snapshot.data ?? ConnectState.idle);
          return Scaffold(
            appBar: AppBar(
              title: Text('Connect to UDP server'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. 連接到 Access Point',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: ssidController,
                      decoration: InputDecoration(hintText: 'AP SSID'),
                    ),
                    TextField(
                      controller: pwController,
                      decoration: InputDecoration(hintText: 'AP Password'),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          connect();
                        },
                        child: Text('開始連接')),
                    Text(statusDescription),
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Text('2. 傳送 Hello 訊息', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          udpManager.write(const Utf8Codec().encode('Hello from client'));
                        },
                        child: Text('hello')),
                    Spacer(),
                    MaterialButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomeScreen()));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.home), Text('GO')],
                        ))
                  ],
                ),
              ),
            ),
          );
        });
  }

  void connect() async {
    await WiFiForIoTPlugin.connect(ssidController.text,
        password: pwController.text, joinOnce: true, security: NetworkSecurity.WPA);
    udpManager.isConnected = await WiFiForIoTPlugin.isConnected();
    if (udpManager.isConnected) {
      state.setState(ConnectState.wificonnected);

      WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(seconds: 1));

      bindTcp();
    }
  }

  void bindTcp() async {
    
    var addressesIListenFrom = InternetAddress.anyIPv4;
    int portIListenOn = 1234; //0 is random
    state.setState(ConnectState.tcpconnecting);
    try {
      Socket socket = await Socket.connect('192.168.4.1', portIListenOn);
      socket.listen(
            (Uint8List event) {
          if (state.connectState != ConnectState.tcpconnected) {
            state.setState(ConnectState.tcpconnected);
          }
        },
        onError: (error) {
          print(error);
          socket.destroy();
          state.setState(ConnectState.idle);
        },
        onDone: () {
          print('Server left.');
          socket.destroy();
          state.setState(ConnectState.idle);
        },
      );
      // send hello
      udpManager.socket = socket;
      udpManager.write(utf8.encode('hello'));
    }catch(e){
      state.setState(ConnectState.idle);
    }
  }

  String getStatusDescription(ConnectState state) {
    switch (state) {
      case ConnectState.idle:
        return '未連接';
      case ConnectState.wificonnecting:
        return '正在嘗試連接Wifi';
      case ConnectState.wificonnected:
        return '已連上Wifi';
      case ConnectState.tcpconnecting:
        return '正在建立TCP連線';
      case ConnectState.tcpconnected:
        return '連線成功';
    }
  }
}
