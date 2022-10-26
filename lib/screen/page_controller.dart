import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/manager/ftp_manager.dart';
import 'package:flutter_wifi_udp/utility/string_tool.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../command/outcommand.dart';
import '../manager/log_manager.dart';
import '../manager/udp_manager.dart';

// sample setup file
// {
//  "Volume":	21,v
//  "Boot_Sound_EN":	1,
//  "Blink_Sound_Mode":	0,
//  "Blink_Time":	600,
//  "Light_Load":	550,
//  "BLE_Name":	"Flasher BLE",
//  "WiFi_SSID":	"KOSO flasher",
//  "WiFi_Password":	"00000000",
//  "Blink_Sound":	"",
//  "Boot_Sound":	""
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

  Map<String, dynamic>? _settings;

  _updateValue(Map<String, dynamic> map) async {
    _volume = map['Volume'] ?? 20.0;
    _blink = map['Blink_Time'] ?? 600.0;
    _enableBootSound = map['Boot_Sound_EN'] == 1;
    _enableBlinkSound = map['Blink_Sound_Mode'] == 1;
    _selectedBootSound = map['Boot_Sound'];
    _selectedBlinkSound = map['Blink_Sound'];
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
    SharedPreferences.getInstance().then((pref){
      var json = pref.getString('setup.json');
      if(json != null && json.isNotEmpty){
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
          ? Column(
              children: [
                Expanded(
                    child: ListView(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  children: [
                    buildSetVolumn(),
                    buildBlinkInterval(),
                    Divider(
                      height: 24,
                    ),
                    buildEnableBootSound(),
                    buildBootSound(),
                    Divider(
                      height: 24,
                    ),
                    buildEnalbeBlinkSound(),
                    buildBlinkSound(),
                  ],
                )),
                ElevatedButton(onPressed: () {}, child: Text('上傳設定'))
              ],
            )
          : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('找不到設定檔'),
            ),
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

  Row buildBlinkInterval() {
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

  Row buildSetVolumn() {
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
}
