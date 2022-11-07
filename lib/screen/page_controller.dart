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
import 'package:fluttertoast/fluttertoast.dart';
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

  var _flashSize = '0,0';
  var _version = 'unknow';

  Map<String, dynamic>? _options;

  _updateValue(Map<String, dynamic> map) async {
    _volume = map['Volume'] ?? 20;
    _blink = map['Blink_Time'] ?? 600;
    _enableBootSound = map['Boot_Sound_EN'] == 1;
    _enableBlinkSound = map['Blink_Sound_Mode'] == 1;
    _selectedBootSound = (map.containsKey('Boot_Sound') ? map['Boot_Sound'] : '');
    _selectedBootSound = _selectedBootSound.replaceAll("/r/", "");
    _selectedBlinkSound = map.containsKey('Blink_Sound') ? map['Blink_Sound'] : '';
    _selectedBlinkSound = _selectedBlinkSound.replaceAll("/r/", "");

    _bleName = map.containsKey('BLE_Name') ? map['BLE_Name'] : '';
    bleNameController.text = _bleName;
    _wifiSsid = map.containsKey('WiFi_SSID') ? map['WiFi_SSID'] : '';
    wifiSsidController.text = _wifiSsid;
    _wifiPw = map.containsKey('WiFi_Password') ? map['WiFi_Password'] : '';
    wifiPwController.text = _wifiPw;
    _wifiOn = map.containsKey('WiFi_Status') ? map['WiFi_Status'] == 1 : false;
    _playSound = map.containsKey('Play_Sound') ? map['Play_Sound'] : '';
    _playSound = _playSound.replaceAll("/r/", "");
    _lightError = map.containsKey('Light_Error_EN') ? map['Light_Error_EN'] == 1 : false;
    // _lightLearning = map.containsKey('LightLearning') ? map['LightLearning'] == 1 : false;
    // _bleUnbound = map.containsKey('BLEUnbond') ? map['BLEUnbond'] == 1 : false;
    _flashSize = map.containsKey('Flash_Size') ? map['Flash_Size'] : '0,0';
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
          print(value);
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
            _volume = (event as ReceivedVolume).volume;
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
            break;
          case ResultOk:
            Fluttertoast.showToast(
                msg: "設定成功",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                fontSize: 16.0
            );
            break;
          case ResultError:
            Fluttertoast.showToast(
                msg: "設定失敗",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.deepOrange,
                textColor: Colors.white,
                fontSize: 16.0
            );
            break;
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
            child: buildSetVolumn(),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildEnableBootSound(),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildEnableBlinkSound(),
                buildBlinkInterval(),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        BleManager.instance.sendCommand(AskLightLearningCommand());
                      },
                      child: Text('方向燈負載學習')),
                ),

              ],
            ),
          ),
        ),
        Card(child: Column(
          children: [
            buildFlashSize(),
            buildVersion(),
          ],
        ),),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              BleManager.instance.sendCommand(AskBleUnboundCommand());
            },
            child: const Text('解除藍芽綁定'),
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
          const Text('版本'),
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
          const Text('記憶體容量'),
          Text(
            '${_flashSize.toUpperCase()} KB',
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
          const Text('Light learning'),
          IconButton(onPressed: (){
            BleManager.instance.sendCommand(AskLightLearningCommand());
          }, icon: const Icon(Icons.upload))
        ],
      ),
    );
  }

  Widget buildLightError() {
    return Row(
      children: [
        const Text('方向燈失效功能'),
        const Spacer(),
        Switch(
            value: _lightError,
            onChanged: (v) {
              setState(() {
                _lightError = v;
              });
              SetupOptions.instance.putLightError(_lightError);
              var cmd = SetLightErrorCommand(_lightError);
              BleManager.instance.sendCommand(cmd);
            }),
      ],
    );
  }

  Widget buildSetupSave() {
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
            onPressed: () {
              var cmd = SetupSaveCommand();
              BleManager.instance.sendCommand(cmd);
            },
            child: const Text('儲存設定')));
  }

  Widget buildFactorySetup() {
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
            onPressed: () {
              var cmd = FactoryResetCommand();
              BleManager.instance.sendCommand(cmd);
            },
            child: const Text('恢復«原廠設定')));
  }

  Widget buildWifiSwitcher() {
    return Row(
      children: [
        const Text('Wifi 開/關'),
        Switch(
            value: _wifiOn,
            onChanged: (enable) {
              setState(() {
                _wifiOn = enable;
              });
              SetupOptions.instance.putWifiStatus(enable);
              var cmd = SetWifiStatusCommand(enable);
              BleManager.instance.sendCommand(cmd);
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
                var cmd = AskPlaySoundCommand(_playSound);
                BleManager.instance.sendCommand(cmd);
              }
            },
            child: Text('Play')),
        const SizedBox(
          width: 8,
        ),
        ElevatedButton(
          onPressed: () {
            var cmd = SetStopSoundCommand();
            BleManager.instance.sendCommand(cmd);
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
                  BleManager.instance.sendCommand(cmd);
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
                  BleManager.instance.sendCommand(cmd);
                }
              : null,
          enableFeedback: true,
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }

  Widget buildEnableBlinkSound() {
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
              BleManager.instance.sendCommand(cmd);
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
                var cmd = SetBootSoundCommand(enable, null);
                BleManager.instance.sendCommand(cmd);
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
          onChanged: _enableBlinkSound ? (double value) {
            setState(() {
              _blink = value.toInt();
            });
          }: null,
          onChangeEnd: _enableBlinkSound ? (double value) {
            var cmd = SetBlinkTimeCommand(_blink.toInt());
            SetupOptions.instance.putBlinkInterval(_blink.toInt());
            BleManager.instance.sendCommand(cmd);
          }: null,
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
        const Text('調整音量'),
        const Spacer(),
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
            BleManager.instance.sendCommand(cmd);
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
        Expanded(
          child: TextFormField(
            controller: bleNameController,
            decoration: InputDecoration(labelText: 'BLE name'),
            onEditingComplete: () {
            },
          ),
        ),
        IconButton(
            onPressed: () {
              _bleName = bleNameController.text;
              SetupOptions.instance.putBleName(_bleName);
              if (_bleName.isNotEmpty) {
                var cmd = SetBleNameCommand(_bleName);
                BleManager.instance.sendCommand(cmd);
              }
            },
            icon: const Icon(Icons.upload))
      ],
    );
  }

  final wifiSsidController = TextEditingController();

  Widget buildWifiSsid() {
    wifiSsidController.text = _wifiSsid;
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: wifiSsidController,
            decoration: InputDecoration(
              labelText: 'Wifi SSID',
            ),
            onEditingComplete: () {
            },
          ),
        ),
        IconButton(
            onPressed: () {
              _wifiSsid = wifiSsidController.text;
              SetupOptions.instance.putWifiSsid(_wifiSsid);
              if (_wifiSsid.isNotEmpty) {
                var cmd = SetWifiSsidCommand(_wifiSsid);
                BleManager.instance.sendCommand(cmd);
              }
            },
            icon: const Icon(Icons.upload))
      ],
    );
  }

  final wifiPwController = TextEditingController();

  Widget buildWifiPw() {
    wifiPwController.text = _wifiPw;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: wifiPwController,
            decoration: InputDecoration(labelText: 'Wifi Password'),
            onEditingComplete: () {
            },
          ),
        ),
        IconButton(
            onPressed: () {
              _wifiPw = wifiPwController.text;
              SetupOptions.instance.putWifiPw(_wifiPw);
              if (_wifiPw.isNotEmpty) {
                var cmd = SetWifiPwCommand(_wifiPw);
                BleManager.instance.sendCommand(cmd);
              }
            },
            icon: const Icon(Icons.upload))
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



}
