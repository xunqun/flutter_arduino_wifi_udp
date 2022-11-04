import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_wifi_udp/command/outcommand.dart';
import 'package:flutter_wifi_udp/constant/state.dart';
import 'package:flutter_wifi_udp/manager/ble_manager.dart';
import 'package:flutter_wifi_udp/manager/setup_options.dart';
import 'package:flutter_wifi_udp/screen/screen_main.dart';

class BleConnectScreen extends StatefulWidget {
  const BleConnectScreen({Key? key}) : super(key: key);

  @override
  State<BleConnectScreen> createState() => _BleConnectScreenState();
}

class _BleConnectScreenState extends State<BleConnectScreen> {
  var stateDesc = '點擊連線以連接閃爍器';
  var state = 0; //0: idle, 1: busy, 2: finish
  StreamSubscription? stateSub;

  @override
  void initState() {
    super.initState();
    BleManager.instance;
    stateSub = appState.connectStateStream.listen((event) {
      switch (event) {
        case ConnectState.bleconnected:
          setState(() {
            stateDesc = '連接到藍芽';
            state = 2;
          });
          askRequiredParameters();
          break;
        case ConnectState.bleconnecting:
          setState(() {
            stateDesc = '正在連接中';
            state = 1;
          });
          break;
        case ConnectState.idle:
          setState(() {
            stateDesc = '點擊連線以連接閃爍器';
            state = 0;
          });
          break;
        default:

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var _bleName = SetupOptions.instance.getValue('BLE_Name');
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 64,
            child: buildElevatedButton(_bleName),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              stateDesc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  ElevatedButton buildElevatedButton(_bleName) {
    switch (state) {
      case 0:
        return ElevatedButton(
            onPressed: () {
              setState(() {
                state = 1;
              });
              BleManager.instance.scanToConnect(_bleName ?? 'Flasher BLE');
            },
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36.0), side: const BorderSide(color: Colors.white)))),
            child: const Text('連線'));
      case 2:
        return ElevatedButton(
          onPressed: () {
            BleManager.instance.disconnect();
          },
          child: const Text('中斷連線'),
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green), shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(36.0), side: const BorderSide(color: Colors.white)))),
        );
      default:
        return ElevatedButton(
            onPressed: null,
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.amber),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36.0), side: const BorderSide(color: Colors.white)))),
            child: const Text('連線中'));
    }
  }

  @override
  void dispose() {
    super.dispose();
    stateSub?.cancel();
  }

  var askCommands = [
    AskVersionCommand(),
    AskFlashSizeCommand(),
    AskLightErrorCommand(),
    AskBleNameCommand(),
    AskWifiSsidCommand(),
    AskWifiPwCommand(),
    AskBlinkSoundCommand(),
    AskBootSoundCommnad(),
    AskBlinkTime(),
    AskVolumeCommand(),
  ];

  void askRequiredParameters() async {
    for (var c in askCommands) {
      setState(() {
        stateDesc = '正在詢問參數 ${c.toString()}';
      });
      print(stateDesc);
      await BleManager.instance.write(c.bytes);
      await Future.delayed(const Duration(milliseconds: 300));

    }

    if(appState.connectState == ConnectState.bleconnected) {
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomeScreen()));
    }
  }
}
