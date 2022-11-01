import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_wifi_udp/manager/ble_manager.dart';
import 'package:flutter_wifi_udp/manager/ftp_manager.dart';
import 'package:flutter_wifi_udp/manager/setup_options.dart';
import 'package:flutter_wifi_udp/utility/string_tool.dart';
import 'package:path_provider/path_provider.dart';

import '../command/incommand.dart';
import '../command/outcommand.dart';
import '../manager/log_manager.dart';
import '../manager/udp_manager.dart';

// sample setup file
// {
// "Volume":	21,
// "Boot_Sound_EN":	1,
// "Blink_Sound_Mode":	0,
// "Blink_Time":	600,
// "Light_Error_EN":	1,
// "Light_Load":	550,
// "Light_Curr":	0,
// "ADC_Cal_Val":	2621,
// "BLE_Name":	"Flasher BLE",
// "WiFi_SSID":	"KOSO flasher",
// "WiFi_Password":	"00000000",
// "Blink_Sound":	"",
// "Boot_Sound":	""
// }
class ControllerPage extends StatefulWidget {
  const ControllerPage({Key? key}) : super(key: key);

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  var progress = 0;
  int _volume = 20;
  int _blink = 600;
  bool _enableBootSound = false;
  bool _enableBlinkSound = false;
  String _selectedBootSound = '';
  String _selectedBlinkSound = '';
  String _bleName = '';
  String _wifiSsid = '';
  String _wifiPw = '';
  var _wifiOn = false;
  var _playSound = '';
  var _lightError = false;
  var _lightLearning = false;
  var _bleUnbound = false;
  var _flashSize = '0/0';
  var _version = 'unknow';

  Map<String, dynamic>? _options;

  _updateValue(Map<String, dynamic> map) async {
    _volume = map['Volume'] ?? 20;
    _blink = map['Blink_Time'] ?? 600;
    _enableBootSound = map['Boot_Sound_EN'] == 1;
    _enableBlinkSound = map['Blink_Sound_Mode'] == 1;
    _selectedBootSound = map.containsKey('Boot_Sound') ? map['Boot_Sound'] : '';
    _selectedBlinkSound = map.containsKey('Blink_Sound') ? map['Blink_Sound'] : '';

    _bleName = map.containsKey('BLE_Name') ? map['BLE_Name'] : '';
    bleNameController.text = _bleName;
    _wifiSsid = map.containsKey('WiFi_SSID') ? map['WiFi_SSID'] : '';
    wifiSsidController.text = _wifiSsid;
    _wifiPw = map.containsKey('WiFi_Password') ? map['WiFi_Password'] : '';
    wifiPwController.text = _wifiPw;
    _wifiOn = map.containsKey('WiFi_Status') ? map['WiFi_Status'] == 1 : false;
    _playSound = map.containsKey('Play_Sound') ? map['Play_Sound'] : '';
    _lightError = map.containsKey('Light_Error_EN') ? map['Light_Error_EN'] == 1 : false;
    _lightLearning = map.containsKey('LightLearning') ? map['LightLearning'] == 1 : false;
    _bleUnbound = map.containsKey('BLEUnbond') ? map['BLEUnbond'] == 1 : false;
    _flashSize = map.containsKey('FlashSize') ? map['FlashSize'] : '0,0';
    _version = map.containsKey('Version') ? map['Version'] : 'unknow';
  }

  _downloadFromRemote() {
    getTemporaryDirectory().then((path) async {
      String _setupPath = path.path + '/setup.json';
      await FtpManager.instance.download('setup.json', _setupPath!);
      File _localSetupFile = File(_setupPath);
      bool _localSetupFileExist = _localSetupFile.existsSync();
      if (_localSetupFileExist) {
        _localSetupFile.readAsString().then((value) async {
          _options = jsonDecode(value);
          if (_options != null) {
            setState(() {
              _updateValue(_options!);
            });
            SetupOptions.instance.loadFromJson(value);
          }
        });
      } else {
        _options = null;
      }
    });
  }

  StreamSubscription? setupSubs = null;
  StreamSubscription? inCmdSubs = null;

  @override
  void initState() {
    super.initState();
    _options = SetupOptions.instance.options;
    if (_options == null) {
      _downloadFromRemote();
    } else {
      _updateValue(_options ?? {});
    }
    setupSubs = SetupOptions.instance.dataStream.listen((event) {
      setState(() {
        _options = event;
      });
    });

    inCmdSubs = BleManager.instance.inCmdStream.listen((event) {
      setState(() {
        switch (event.runtimeType) {
          case ReceivedVolume:
            _volume = (event as ReceivedVolume).volumn;
            break;
          case ReceivedBlinktime:
            _blink = (event as ReceivedBlinktime).value;
            break;
          case ReceivedBootSound:
            _selectedBootSound = (event as ReceivedBootSound).value;
            break;
          case ReceivedBleName:
            _bleName = (event as ReceivedBleName).value;
            break;
          case ReceivedBlinkSound:
            _selectedBlinkSound = (event as ReceivedBlinkSound).value;
            break;
          case ReceivedWiFiSSID:
            _wifiSsid = (event as ReceivedWiFiSSID).value;
            break;
          case ReceivedWiFiPwd:
            _wifiPw = (event as ReceivedWiFiPwd).value;
            break;
          case ReceivedWiFiStatus:
            _wifiOn = (event as ReceivedWiFiStatus).value == 1;
            break;
          case ReceivedLightError:
            _lightError = (event as ReceivedLightError).value == 1;
            break;
          case ReceivedVersion:
            _version = (event as ReceivedVersion).value;
            break;
          case ReceivedFlashSize:
            _flashSize =
                (event as ReceivedFlashSize).spare.toString() + ',' + (event as ReceivedFlashSize).total.toString();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    setupSubs?.cancel();
    inCmdSubs?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
        actions: [
          IconButton(
              tooltip: '由FTP下載',
              onPressed: () {
                _downloadFromRemote();
              },
              icon: const Icon(Icons.file_download))
        ],
      ),
      body: _options != null
          ? buildControllList()
          : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('找不到設定檔'),
            ),
    );
  }

  ListView buildControllList() {
    return ListView(
      children: [
        Card(
          child: buildBleStatus(),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildSetVolumn(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskVolumeCommand());
                        },
                        child: Text('詢問音量')),
                  ],
                )
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildEnableBootSound(),
                buildBootSound(),
                buildPlaySound(),
                ElevatedButton(
                    onPressed: () {
                      sendCommand(AskBootSoundCommnad());
                    },
                    child: Text("詢問開機音效"))
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildBlinkInterval(),
                buildEnalbeBlinkSound(),
                buildBlinkSound(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskBlinkTime());
                        },
                        child: Text('詢問閃爍時間')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskBlinkSoundCommand());
                        },
                        child: Text("詢問閃爍音效")),
                  ],
                )
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildWifiSwitcher(),
                buildWifiSsid(),
                buildWifiPw(),
                buildBleName(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskWifiSsidCommand());
                        },
                        child: Text('詢問SSID')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskWifiPwCommand());
                        },
                        child: Text('詢問PW')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskBleNameCommand());
                        },
                        child: Text('詢問BLE')),
                  ],
                )
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLightError(),
                buildLightLearning(),
                buildBleUnbound(),
                buildFlashSize(),
                buildVersion(),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskLightErrorCommand());
                        },
                        child: Text('詢問LightError')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskFlashSizeCommand());
                        },
                        child: Text('詢問Size')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskVersionCommand());
                        },
                        child: Text('詢問Version')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskBleUnboundCommand());
                        },
                        child: Text('詢問BleUnbound')),
                    ElevatedButton(
                        onPressed: () {
                          sendCommand(AskLightLearningCommand());
                        },
                        child: Text('詢問LightLearning')),
                  ],
                )
              ],
            ),
          ),
        ),
        buildFactorySetup(),
        buildSetupSave(),
      ],
    );
  }

  StreamBuilder<BluetoothDeviceState> buildBleStatus() {
    return StreamBuilder<BluetoothDeviceState>(
        stream: BleManager.instance.stateStream,
        initialData: BluetoothDeviceState.disconnected,
        builder: (context, snapshot) {
          BluetoothDeviceState state = BleManager.instance.state;
          return ListTile(
            tileColor: state == BluetoothDeviceState.connected ? Colors.greenAccent : Colors.grey,
            title: const Text('藍芽狀態'),
            subtitle: Text(state == BluetoothDeviceState.connected ? '已連接' : '尚未連接，將無法上傳設定，點擊以連接'),
            trailing: getStateIcon(state),
            onTap: () {
              switch (state) {
                case BluetoothDeviceState.disconnected:
                  BleManager.instance.scanToConnect(_bleName.isNotEmpty ? _bleName : 'Flasher BLE');
                  break;
                case BluetoothDeviceState.connected:
                  BleManager.instance.disconnect();
                  break;
                default:
              }
            },
          );
        });
  }

  Widget buildVersion() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Version'),
          Text(
            _version.toString().toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget buildFlashSize() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Flash Size'),
          Text(
            '${_flashSize.toUpperCase()} KB',
            style: TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget buildBleUnbound() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('BLE Unbound'),
          Text(
            _bleUnbound.toString().toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget buildLightLearning() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Light learning'),
          Text(
            _lightLearning.toString().toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget buildLightError() {
    return Row(
      children: [
        const Text('Light error'),
        const Spacer(),
        Switch(
            value: _lightError,
            onChanged: (v) {
              setState(() {
                _lightError = v;
              });
              SetupOptions.instance.putLightError(_lightError);
              var cmd = SetLightErrorCommand(_lightError);
              sendCommand(cmd);
            }),
      ],
    );
  }

  Widget buildSetupSave() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () {
                var cmd = SetupSaveCommand();
                sendCommand(cmd);
              },
              child: Text('Setup Save'))),
    );
  }

  Widget buildFactorySetup() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () {
                var cmd = FactoryResetCommand();
                sendCommand(cmd);
              },
              child: Text('Factory Setup'))),
    );
  }

  Widget buildWifiSwitcher() {
    return Row(
      children: [
        Text('Wifi 開/關'),
        Switch(
            value: _wifiOn,
            onChanged: (enable) {
              setState(() {
                _wifiOn = enable;
              });
              SetupOptions.instance.putWifiStatus(enable);
              var cmd = SetWifiStatusCommand(enable);
              sendCommand(cmd);
            })
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  Widget buildPlaySound() {
    var items = FtpManager.instance
        .getFiles()
        .map(
          (e) => DropdownMenuItem<String>(
            child: Text(utf8Decode(e.name)),
            value: utf8Decode(e.name),
          ),
        )
        .toList();
    items.add(const DropdownMenuItem(
      child: Text('無'),
      value: '',
    ));

    return Row(
      children: [
        DropdownButton(
            value: _playSound,
            items: items,
            onChanged: (path) {
              setState(() {
                _playSound = path.toString();
                SetupOptions.instance.putPlaySound(_playSound);
              });
            }),
        Spacer(),
        ElevatedButton(
            onPressed: () {
              if (_playSound.isNotEmpty) {
                var cmd = SetPlaySoundCommand(_playSound);
                sendCommand(cmd);
              }
            },
            child: Text('Play')),
        SizedBox(
          width: 8,
        ),
        ElevatedButton(
          onPressed: () {
            var cmd = SetStopSoundCommand();
            sendCommand(cmd);
          },
          child: Text('Stop'),
        ),
      ],
    );
  }

  Widget buildBlinkSound() {
    var items = FtpManager.instance
        .getFiles()
        .map(
          (e) => DropdownMenuItem<String>(
            child: Text(utf8Decode(e.name)),
            value: utf8Decode(e.name),
          ),
        )
        .toList();
    // add none option
    items.add(DropdownMenuItem(
      child: Text(
        '無',
      ),
      value: '',
    ));
    return Row(
      children: [
        const Text('設定閃爍音效'),
        const Spacer(),
        DropdownButton(
          value: _selectedBlinkSound,
          items: items,
          onChanged: _enableBlinkSound
              ? (path) {
                  setState(() {
                    _selectedBlinkSound = path.toString();
                  });
                  SetupOptions.instance.putBlinkSound(_selectedBootSound);
                  var cmd = SetBlinkSoundCommand(_enableBlinkSound, _selectedBlinkSound);
                  sendCommand(cmd);
                }
              : null,
          enableFeedback: true,
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }

  Widget buildBootSound() {
    var items = FtpManager.instance
        .getFiles()
        .map(
          (e) => DropdownMenuItem<String>(
            child: Text(utf8Decode(e.name)),
            value: utf8Decode(e.name),
          ),
        )
        .toList();
    // add none option
    items.add(DropdownMenuItem(
      child: Text(
        '無',
      ),
      value: '',
    ));
    return Row(
      children: [
        const Text('設定開機音效'),
        const Spacer(),
        DropdownButton(
          value: _selectedBootSound,
          items: items,
          onChanged: _enableBootSound
              ? (path) {
                  setState(() {
                    _selectedBootSound = path.toString();
                  });
                  SetupOptions.instance.putBootSound(_selectedBootSound);
                  var cmd = SetBootSoundCommand(_enableBootSound, _selectedBootSound);
                  sendCommand(cmd);
                }
              : null,
          enableFeedback: true,
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }

  Widget buildEnalbeBlinkSound() {
    return Row(
      children: [
        Text('自訂閃爍音效'),
        Spacer(),
        Switch(
            value: _enableBlinkSound,
            onChanged: (enable) {
              setState(() {
                _enableBlinkSound = enable;
              });
              SetupOptions.instance.putEnableBlinkSound(enable);
              var cmd = SetBlinkSoundCommand(_enableBlinkSound, _selectedBlinkSound);
              sendCommand(cmd);
            })
      ],
    );
  }

  Widget buildEnableBootSound() {
    return Row(
      children: [
        Text('開機音效'),
        Spacer(),
        Switch(
            value: _enableBootSound,
            onChanged: (enable) {
              setState(() {
                _enableBootSound = enable;
                SetupOptions.instance.putEnableBootSound(enable);
                var cmd = SetBootSoundCommand(enable, _selectedBootSound);
                sendCommand(cmd);
              });
            })
      ],
    );
  }

  Widget buildBlinkInterval() {
    return Row(
      children: [
        Text('閃爍時間'),
        Spacer(),
        Text('${_blink.toInt()}'),
        Slider(
          onChanged: (double value) {
            setState(() {
              _blink = value.toInt();
            });
          },
          onChangeEnd: (double value) {
            var cmd = SetBlinkTimeCommand(_blink.toInt());
            SetupOptions.instance.putBlinkInterval(_blink.toInt());
            sendCommand(cmd);
          },
          value: _blink.toDouble(),
          min: 600,
          max: 850,
          label: '閃爍時間',
        ),
      ],
    );
  }

  Widget buildSetVolumn() {
    return Row(
      children: [
        Text('調整音量'),
        Spacer(),
        Text('${_volume.toInt()}'),
        Slider(
          onChanged: (double value) {
            setState(() {
              _volume = value.toInt();
            });
          },
          onChangeEnd: (double value) {
            var cmd = SetVolumeCommand(_volume.toInt());
            SetupOptions.instance.putVolume(_volume.toInt());
            sendCommand(cmd);
          },
          value: _volume.toDouble(),
          min: 0,
          max: 21,
        ),
      ],
    );
  }

  final bleNameController = TextEditingController();

  Widget buildBleName() {
    bleNameController.text = _bleName;
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: bleNameController,
            decoration: InputDecoration(labelText: 'BLE name'),
            onEditingComplete: () {
              setState(() {
                _bleName = bleNameController.text;
              });
              SetupOptions.instance.putBleName(_bleName);
            },
          ),
        ),
        IconButton(
            onPressed: () {
              if (_bleName.isNotEmpty) {
                var cmd = SetBleNameCommand(_bleName);
                sendCommand(cmd);
              }
            },
            icon: const Icon(Icons.send))
      ],
    );
  }

  final wifiSsidController = TextEditingController();

  Widget buildWifiSsid() {
    wifiSsidController.text = _wifiSsid;
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: wifiSsidController,
            decoration: InputDecoration(
              labelText: 'Wifi SSID',
            ),
            onEditingComplete: () {
              setState(() {
                _wifiSsid = wifiSsidController.text;
              });
              SetupOptions.instance.putWifiSsid(_wifiSsid);
            },
          ),
        ),
        IconButton(
            onPressed: () {
              if (_wifiSsid.isNotEmpty) {
                var cmd = SetWifiSsidCommand(_wifiSsid);
                sendCommand(cmd);
              }
            },
            icon: const Icon(Icons.send))
      ],
    );
  }

  final wifiPwController = TextEditingController();

  Widget buildWifiPw() {
    wifiPwController.text = _wifiPw;
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: wifiPwController,
            decoration: InputDecoration(labelText: 'Wifi Password'),
            onEditingComplete: () {
              setState(() {
                _wifiPw = wifiPwController.text;
              });
              SetupOptions.instance.putWifiPw(_wifiPw);
            },
          ),
        ),
        IconButton(
            onPressed: () {
              if (_wifiPw.isNotEmpty) {
                var cmd = SetWifiPwCommand(_wifiPw);
                sendCommand(cmd);
              }
            },
            icon: const Icon(Icons.send))
      ],
    );
  }

  Widget getStateIcon(BluetoothDeviceState state) {
    IconData iconDate = Icons.more_horiz;
    if (state == BluetoothDeviceState.connected) {
      iconDate = Icons.cloud_done;
      return Icon(
        iconDate,
        color: Colors.green,
      );
    } else if (state == BluetoothDeviceState.disconnected) {
      iconDate = Icons.cloud_off;
      return Icon(
        iconDate,
        color: Colors.red,
      );
    } else {
      return Icon(iconDate);
    }
  }

  var writting = false;
  var wrintingTimeStamp = 0;
  void sendCommand(OutCommanad cmd) async{
    if (BleManager.instance.state == BluetoothDeviceState.connected) {
      var now = DateTime.now().millisecondsSinceEpoch;
      if (now - wrintingTimeStamp > 1000) writting = false; // avoid send too many at one time & stuck
      if (!writting) {
        var sendSize = 20;
        if (cmd.bytes.length > sendSize) {
          var counter = 0;
          while (counter < cmd.bytes.length) {
            var subcmd = cmd.bytes.sublist(counter, min(counter + sendSize, cmd.bytes.length));
            await BleManager.instance.write(subcmd);
            // print('send bytes ${subcmd.length}');
            // print('${subcmd.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}');
            await Future.delayed(const Duration(milliseconds: 150));
            counter += sendSize;
          }
        } else {
          BleManager.instance.write(cmd.bytes);
        }
        writting = false;
        logManager.addSendRaw(cmd.bytes, msg: cmd.toString(), desc: cmd.string);
      }
    }
  }
}
