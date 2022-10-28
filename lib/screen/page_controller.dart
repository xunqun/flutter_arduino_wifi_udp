import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_wifi_udp/manager/ble_manager.dart';
import 'package:flutter_wifi_udp/manager/ftp_manager.dart';
import 'package:flutter_wifi_udp/utility/string_tool.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  var _flashSize = 0;
  var _version = 'unknow';

  Map<String, dynamic>? _settings;

  _updateValue(Map<String, dynamic> map) async {
    _volume = map['Volume'] ?? 20.0;
    _blink = map['Blink_Time'] ?? 600.0;
    _enableBootSound = map['Boot_Sound_EN'] == 1;
    _enableBlinkSound = map['Blink_Sound_Mode'] == 1;
    _selectedBootSound = map['Boot_Sound'];
    _selectedBlinkSound = map['Blink_Sound'];

    _bleName = map.containsKey('BLE_Name') ? map['BLE_Name'] : '';
    bleNameController.text = _bleName;
    _wifiSsid = map.containsKey('WiFi_SSID') ? map['WiFi_SSID'] : '';
    wifiSsidController.text = _wifiSsid;
    _wifiPw = map.containsKey('WiFi_Password') ? map['WiFi_Password'] : '';
    wifiPwController.text = _wifiPw;
    _wifiOn = map.containsKey('WiFiStatus') ? map['WiFiStatus'] : false;
    _playSound = map.containsKey('PlaySound') ? map['PlaySound'] : '';
    _lightError = map.containsKey('Light_Error_EN') ? map['Light_Error_EN'] == 1 : false;
    _lightLearning = map.containsKey('LightLearning') ? map['LightLearning'] : false;
    _bleUnbound = map.containsKey('BLEUnbond') ? map['BLEUnbond'] : false;
    _flashSize = map.containsKey('FlashSize') ? map['FlashSize'] : 0;
    _version = map.containsKey('Version') ? map['Version'] : 'unknow';


  }

  _downloadFromRemote() {
    getTemporaryDirectory().then((path) async {
      String _setupPath = path.path + '/setup.json';
      await FtpManager.instance.download('setup.json', _setupPath!);
      File _localSetupFile = File(_setupPath);
      bool _localSetupFileExist = _localSetupFile.existsSync();
      setState(() {
        if (_localSetupFileExist) {
          _localSetupFile.readAsString().then((value) async {
            setState(() {
              _settings = jsonDecode(value);
              if (_settings != null) {
                _updateValue(_settings!);
              }
            });
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('setup.json', value);
          });
        } else {
          _settings = null;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((pref) {
      var json = pref.getString('setup.json');
      if (json != null && json.isNotEmpty) {
         _updateValue(jsonDecode(json));
      }
    });
    _downloadFromRemote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
        actions: [
          IconButton(
              onPressed: () {
                _downloadFromRemote();
              },
              icon: const Icon(Icons.file_download))
        ],
      ),
      body: _settings != null
          ? buildListView()
          : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('找不到設定檔'),
            ),
    );
  }

  ListView buildListView() {
    return ListView(
            children: [
              Card(
                child: StreamBuilder<BluetoothDeviceState>(
                    stream: BleManager.instance.stateStream,
                    initialData: BluetoothDeviceState.disconnected,
                    builder: (context, snapshot) {
                      BluetoothDeviceState state = BleManager.instance.state;
                      return ListTile(
                        title: const Text('藍芽狀態'),
                        subtitle: Text(state == BluetoothDeviceState.connected ? '已連接' : '尚未連接，將無法上傳設定'),
                        trailing: getStateIcon(state),
                        onTap: () {
                          switch(state){
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
                    }),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildSetVolumn(),
                      buildBlinkInterval(),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [buildEnableBootSound(), buildBootSound(), buildPlaySound()],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildEnalbeBlinkSound(),
                      buildBlinkSound(),
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
                      buildLightLearning(),
                      buildBleUnbound(),
                      buildFlashSize(),
                      buildVersion()
                    ],
                  ),
                ),
              ),
              buildFactorySetup(),
              buildSetupSave(),
            ],
          );
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
            '${_flashSize.toString().toUpperCase()} KB',
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
        Text('Light error'),
        Spacer(),
        Switch(
            value: _lightError,
            onChanged: (v) {
              setState(() {
                _lightError = v;
              });
            }),
      ],
    );
  }

  Widget buildSetupSave() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: Text('Setup Save'))),
    );
  }

  Widget buildFactorySetup() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: Text('Factory Setup'))),
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
            value: e.name,
          ),
        )
        .toList();
    items.add(const DropdownMenuItem(
      child: Text(
        '無',
      ),
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
              });
            }),
        Spacer(),
        ElevatedButton(onPressed: () {}, child: Text('Play')),
        SizedBox(
          width: 8,
        ),
        ElevatedButton(
          onPressed: () {},
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
            value: e.name,
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
            value: e.name,
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
            var cmd = BlinkTimeCommand(_blink.toInt());
            udpManager.write(cmd.bytes);
            logManager.addSendRaw(cmd.bytes, msg: 'SET BLINK', desc: cmd.string);
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
            var cmd = VolumeCommand(_volume.toInt());
            udpManager.write(cmd.bytes);
            logManager.addSendRaw(cmd.bytes, msg: 'SET VOLUME', desc: cmd.string);
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
    return TextFormField(
      controller: bleNameController,
      decoration: InputDecoration(labelText: 'BLE name'),
      onEditingComplete: () {
        _bleName = bleNameController.text;
      },
    );
  }

  final wifiSsidController = TextEditingController();

  Widget buildWifiSsid() {
    wifiSsidController.text = _wifiSsid;
    return TextFormField(
      controller: wifiSsidController,
      decoration: InputDecoration(
        labelText: 'Wifi SSID',
      ),
      onEditingComplete: () {
        _wifiSsid = wifiSsidController.text;
      },
    );
  }

  final wifiPwController = TextEditingController();

  Widget buildWifiPw() {
    wifiPwController.text = _wifiPw;
    return TextFormField(
      controller: wifiPwController,
      decoration: InputDecoration(labelText: 'Wifi Password'),
      onEditingComplete: () {
        _wifiPw = wifiPwController.text;
      },
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
