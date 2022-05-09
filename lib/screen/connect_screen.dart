import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/screen/home_screen.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  RawDatagramSocket? rawDatagramSocket = null;

  @override
  Widget build(BuildContext context) {
    final TextEditingController ssidController = TextEditingController(text: 'HiAp');
    final TextEditingController pwController = TextEditingController(text: 'BB9ESERVER');
    final TextEditingController ipController = TextEditingController(text: '192.168.4.1');
    final TextEditingController portController = TextEditingController(text: '1234');
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
                    WiFiForIoTPlugin.connect(ssidController.text,
                        password: pwController.text, joinOnce: true, security: NetworkSecurity.WPA);
                  },
                  child: Text('Wifi AP')),
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: Text('2. 設定 Remote IP/Port', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextField(
                controller: ipController,
                decoration: InputDecoration(hintText: 'IP'),
              ),
              TextField(
                controller: portController,
                decoration: InputDecoration(hintText: 'Port'),
              ),
              ElevatedButton(
                  onPressed: () {
                    var addressesIListenFrom = InternetAddress.anyIPv4;
                    int portIListenOn = int.parse(portController.text); //0 is random
                    RawDatagramSocket.bind(addressesIListenFrom, portIListenOn).then((RawDatagramSocket socket) {
                      socket.broadcastEnabled = true;
                      socket.listen((event) {
                        switch (event) {
                          case RawSocketEvent.read:
                            Datagram? dg = socket.receive();
                            if (dg != null) {
                              List<int> bytes = dg.data.toList();
                              var text = String.fromCharCodes(bytes);
                              print(text);
                            }
                            socket.writeEventsEnabled = true;
                            break;
                          case RawSocketEvent.write:
                            break;
                          case RawSocketEvent.closed:
                            print('Client disconnected.');
                        }

                        // rawDatagramSocket?.close();
                      });
                      rawDatagramSocket = socket;
                      rawDatagramSocket?.send(
                          Utf8Codec().encode('Hello from client'), InternetAddress('192.168.4.255'), 1234);
                    });
                  },
                  child: Text('監聽')),
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: Text('3. 傳送 Hello 訊息', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                  onPressed: () {
                    rawDatagramSocket?.send(
                        Utf8Codec().encode('Hello from client'), InternetAddress('192.168.4.255'), 1234);
                  },
                  child: Text('Send')),
              Spacer(),
              MaterialButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomeScreen()));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.home), Text('HOME')],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
