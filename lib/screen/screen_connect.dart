import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    var udpManager = context.watch<UdpManager>();
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
                '1. 連接到 Access Point, 192.168.4.1:1234',
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
                  child: Text('Wifi AP')),
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
                  onPressed:  () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomeScreen()));
                  } ,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.home), Text('GO')],
                  ))
            ],
          ),
        ),
      ),
    );
  }

  void connect() async{

    await WiFiForIoTPlugin.connect(ssidController.text,
        password: pwController.text, joinOnce: true, security: NetworkSecurity.WPA);
    udpManager.isConnected = await WiFiForIoTPlugin.isConnected();
    if(udpManager.isConnected){
      WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(Duration(seconds: 1));
      var addressesIListenFrom = InternetAddress.anyIPv4;
      // var addressesIListenFrom = InternetAddress('192.168.4.100');
      int portIListenOn = 1234; //0 is random

      RawDatagramSocket.bind(addressesIListenFrom, portIListenOn).then((RawDatagramSocket socket) {
        udpManager.rawDatagramSocket = socket;
        // udpManager.write(Utf8Codec().encode('Connected to client'));
        udpManager.isConnected = true;
      }).catchError((e){
        log(e.toString());
        udpManager.isConnected = false;
      });
    }
  }
}
