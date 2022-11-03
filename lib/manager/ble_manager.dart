import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_wifi_udp/command/incommand.dart';
import 'package:flutter_wifi_udp/manager/log_manager.dart';
import 'package:flutter_wifi_udp/utility/string_tool.dart';

class BleManager {
  static BleManager? _instance;

  StreamSubscription<List<int>>? _byteSubs;

  static BleManager get instance {
    if(_instance == null) _instance = BleManager();
    return _instance!;
  }

  final SERVICE_UUID = '0000ABF0-0000-1000-8000-00805F9B34FB';
  final CHAR_UUID = '0000ABF1-0000-1000-8000-00805F9B34FB';
  final FlutterBluePlus _blue = FlutterBluePlus.instance;

  // connect state
  final StreamController<BluetoothDeviceState> _stateController = StreamController<BluetoothDeviceState>.broadcast();
  StreamSink<BluetoothDeviceState> get _stateSink => _stateController.sink;
  Stream<BluetoothDeviceState> get stateStream => _stateController.stream;

  // received cmd
  final StreamController<InCommand> _inCmdController = StreamController<InCommand>.broadcast();
  StreamSink<InCommand> get _inCmdSink => _inCmdController.sink;
  Stream<InCommand> get inCmdStream => _inCmdController.stream;

  String? _name;
  BluetoothDevice? _device;
  BluetoothService? _service;
  BluetoothCharacteristic? _characteristic;
  BluetoothDeviceState state = BluetoothDeviceState.disconnected;



  BleManager() {
    _blue.scanResults.listen((results) async {
      if (_name != null) {
        if(_device == null) {
          try {
            var result = results.firstWhere((element) => element.device.name == _name);
            _device = result.device;
            await _device!.connect(timeout: const Duration(seconds: 6), autoConnect: false);
            _handleConnect();
          } catch (e) {

          }
        }
      }
    });
  }

  scanToConnect(String name) {
    _name = name;
    _blue.startScan(timeout: const Duration(seconds: 6));
  }

  disconnect(){
    _device?.disconnect();
    _device = null;
  }

  destory() {
    _byteSubs?.cancel();
    disconnect();
    _blue.stopScan();
    _instance = null;
  }

  write(List<int> bytes) {
    _characteristic?.write(bytes, withoutResponse: true);
  }

  _handleConnect() async {
    _device!.state.listen(_handleState);
    // await _device!.requestMtu(64);
    await Future.delayed(const Duration(milliseconds: 1500));
    try {
      List<BluetoothService> services = await _device!.discoverServices();
      _service = services.firstWhere((s){
        return s.uuid.toString().toUpperCase() == SERVICE_UUID;
      });
      _characteristic = _service!.characteristics.firstWhere((c) => c.uuid.toString().toUpperCase() == CHAR_UUID);
      _byteSubs = _characteristic!.onValueChangedStream.listen(_handleBytes);
      await Future.delayed(Duration(milliseconds: 500));
      await _characteristic!.setNotifyValue(true);

    } catch (e) {
      // service not found
      print(e.toString());
    }
  }

  _handleState(BluetoothDeviceState state) {
    this.state = state;
    _stateSink.add(state);
    if(state == BluetoothDeviceState.disconnected){
      destory();
    }
  }

  /// Buffer to wait and keep the whole command
  List<int> _buffer = [];
  /// Handle the incoming bytes to assumble as a complete command
  var startFound = false;
  void _handleBytes(List<int> raw) {
    for (int i = 0; i < raw.length; i++) {
      if (raw[i] == 0x0d && raw[i + 1] == 0x0a) {
        if (_buffer.isEmpty) {
          // this is start bytes
          _buffer.add(raw[i]);
          startFound = true;
        } else{
          // this is end bytes
          _buffer.add(0x0d);
          _buffer.add(0x0a);
          print(_buffer.toList().map((e) => '0x${e.toRadixString(16)}').toList().toString());
          _handleData(_buffer);
          _buffer.clear();
          break;
        }
      } else {
        _buffer.add(raw[i]);
      }
    }
  }

  void _handleData(List<int> buffer) {
    var cmd = InCommand.factory(buffer);
    if(cmd != null){
      logManager.addReceiveRaw(buffer, msg: cmd.toString(), desc: utf8.decode(buffer));
      _inCmdSink.add(cmd);
    }else{
      logManager.addReceiveRaw(buffer, msg: "UNKNOW EVENT");
    }
  }
}