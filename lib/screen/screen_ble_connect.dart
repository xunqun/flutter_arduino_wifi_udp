import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_wifi_udp/command/outcommand.dart';
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
    stateSub = BleManager.instance.stateStream.listen((event) {
      switch(event){
        case BluetoothDeviceState.connected:
          setState((){
            stateDesc = '連接到藍芽';
            state = 1;
          });
          askRequiredParameters();

          break;
        case BluetoothDeviceState.connecting:
          setState(() {
            stateDesc = '正在連接中';
            state = 1;
          });
          break;
        case BluetoothDeviceState.disconnecting:
          setState(() {
            stateDesc = '正在中斷';
            state = 1;
          });
          break;
        default:
          setState(() {
            stateDesc = '點擊連線以連接閃爍器';
            state = 1;
          });
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
            child: ElevatedButton(onPressed: state == 0 ? (){
              setState(() {
                stateDesc = "開始搜尋";
              });
              BleManager.instance.scanToConnect(_bleName ?? 'Flasher BLE');
            }: null, child: Text('連線'), style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36.0),
                        side: BorderSide(color: Colors.white)
                    )
                )
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(stateDesc, style: TextStyle(fontSize: 12, color: Colors.grey), ),
          )
        ],
      ),
    );
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
  void askRequiredParameters() async{
    for(var c in askCommands){
      BleManager.instance.write(c.bytes);
      await Future.delayed(Duration(milliseconds: 200));
    }
    setState(() {
      state = 2;
    });
    await Future.delayed(Duration(seconds: 2))
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => HomeScreen()));
  }
}
