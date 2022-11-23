import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/constant/state.dart';
import 'package:flutter_wifi_udp/manager/ftp_manager.dart';
import 'package:flutter_wifi_udp/manager/setup_options.dart';
import 'package:flutter_wifi_udp/manager/udp_manager.dart';
import 'package:flutter_wifi_udp/screen/screen_main.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  
  final TextEditingController ssidController = TextEditingController(text: 'KOSO flasher');
  final TextEditingController pwController = TextEditingController(text: '00000000');
  String statusDescription = "未連線";
  ConnectState connectState = ConnectState.idle;

  @override
  Widget build(BuildContext context) {
    if(SetupOptions.instance.options?.containsKey('WiFi_SSID') == true){
      ssidController.text = SetupOptions.instance.options!['WiFi_SSID'];
    }
    if(SetupOptions.instance.options?.containsKey('WiFi_Password') == true){
      pwController.text = SetupOptions.instance.options!['WiFi_Password'];
    }
    return StreamBuilder<ConnectState>(
        stream: appState.connectStateStream,
        initialData: ConnectState.idle,
        builder: (context, snapshot) {
          connectState = snapshot.data ?? ConnectState.idle;
          statusDescription = getStatusDescription(snapshot.data ?? ConnectState.idle);
          return Scaffold(
            appBar: AppBar(
              title: Text('連接'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '連接到WIFI',
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
                  SizedBox(
                    height: 16,
                  ),
                  SizedBox(width: double.infinity, height: 56, child: getAction(connectState)),
                  Text(statusDescription),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomeScreen()));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.home), Text('GO')],
                        )),
                  )
                ],
              ),
            ),
          );
        });
  }

  void connect() async {
    appState.setState(ConnectState.wificonnecting);
    var success = await WiFiForIoTPlugin.connect(ssidController.text,
            password: pwController.text, joinOnce: true, security: NetworkSecurity.WPA)
        .timeout(Duration(seconds: 10), onTimeout: () => false);
    wifiManager.isConnected = success;
    if (wifiManager.isConnected) {
      appState.setState(ConnectState.wificonnected);

      WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(seconds: 1));
      await bindFtp();
    } else {
      appState.setState(ConnectState.idle);
    }
  }

  void disconnect() {
    FtpManager.instance.disconnect();
    WiFiForIoTPlugin.disconnect();
    appState.setState(ConnectState.idle);
  }

  Future bindFtp() async {
    appState.setState(ConnectState.ftpconnecting);
    var success = await FtpManager.instance.connect().timeout(const Duration(seconds: 6), onTimeout: () => false) ?? false;
    appState.setState(success ? ConnectState.ftpconnected : ConnectState.idle);
    if (success) {
      try {
        await FtpManager.instance.refreshFiles();
      } catch (e) {
        print(e.toString());
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (c) => const HomeScreen()));
    }
  }

  Future bindTcp() async {
    var addressesIListenFrom = InternetAddress.anyIPv4;
    int portIListenOn = 2024; //0 is random
    appState.setState(ConnectState.tcpconnecting);
    try {
      Socket socket = await Socket.connect('192.168.4.1', portIListenOn);
      socket.listen(
        (Uint8List event) {
          if (appState.connectState != ConnectState.tcpconnected) {
            appState.setState(ConnectState.tcpconnected);
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print(error);
          }
          socket.destroy();
          appState.setState(ConnectState.idle);
        },
        onDone: () {
          if (kDebugMode) {
            print('Server left.');
          }
          socket.destroy();
          appState.setState(ConnectState.idle);
        },
      );
      // send hello
      wifiManager.socket = socket;
      wifiManager.write(utf8.encode('hello'));
    } catch (e) {
      appState.setState(ConnectState.idle);
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
      case ConnectState.blescanning:
        return '搜尋中';
      case ConnectState.tcpconnecting:
        return '正在建立TCP連線';
      case ConnectState.ftpconnecting:
        return '正在建立FTP連線';
      case ConnectState.bleconnecting:
        return '正在藍芽連線';
      case ConnectState.tcpconnected:
      case ConnectState.ftpconnected:
      case ConnectState.bleconnected:
        return '連線成功';
    }
  }

  Widget getAction(ConnectState state) {
    switch (state) {
      case ConnectState.idle:
        return ElevatedButton(
            onPressed: () {
              connect();
            },
            child: Text('開始連接'));
      case ConnectState.ftpconnecting:
      case ConnectState.wificonnecting:
      case ConnectState.wificonnected:
        return ElevatedButton(onPressed: null, child: Text('...'));
      default:
        return ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.red,
            ),
            onPressed: () {
              disconnect();
            },
            child: Text('中斷連線'));
    }
  }
}
