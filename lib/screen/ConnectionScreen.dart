import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  RawDatagramSocket? rawDatagramSocket = null;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to UDP server'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              const Text('192.168.4.255:1234'),
              ElevatedButton(
                  onPressed: () {
                    var addressesIListenFrom = InternetAddress.anyIPv4;
                    int portIListenOn = 1234; //0 is random
                    RawDatagramSocket.bind(addressesIListenFrom, portIListenOn).then((RawDatagramSocket socket) {
                      socket.broadcastEnabled = true;
                      socket.listen((event) {
                        switch(event) {
                          case RawSocketEvent.read :
                            Datagram? dg = socket.receive();
                            if(dg != null) {
                              List<int> bytes = dg.data.toList();
                              var text = String.fromCharCodes(bytes);
                              print(text);
                            }
                            socket.writeEventsEnabled = true;
                            break;
                          case RawSocketEvent.write :
                            break;
                          case RawSocketEvent.closed :
                            print('Client disconnected.');
                        }

                        // rawDatagramSocket?.close();
                      });
                      rawDatagramSocket = socket;
                      rawDatagramSocket?.send(Utf8Codec().encode('Hello from client'), InternetAddress('192.168.4.255'), 1234);
                    });
                  },
                  child: Text('連線')),
                  ElevatedButton(onPressed: (){
                    rawDatagramSocket?.send(Utf8Codec().encode('Hello from client'), InternetAddress('192.168.4.255'), 1234);
                  }, child: Text('Send'))
            ],
          ),
        ),
      ),
    );
  }
}
