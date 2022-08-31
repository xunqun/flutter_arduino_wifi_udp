import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../command/outcommand.dart';
import '../manager/log_manager.dart';
import '../manager/udp_manager.dart';

class ControllerPage extends StatefulWidget {
  const ControllerPage({Key? key}) : super(key: key);

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  var progress = 0;
  double _volume = 20.0;
  double _blink = 600.0;
  bool _enableBootSound = false;
  SharedPreferences? prefs;
  String _bootSound = '/aaa.mp3';

  @override
  void initState() {
    initValue();
    super.initState();
  }

  initValue() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs?.getDouble('volume') ?? 20.0;
      _blink = prefs?.getDouble('blink') ?? 600.0;
      _enableBootSound = prefs?.getBool('enableBootSound') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Controller')),
      body: ListView(
        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
        children: [
          buildSetVolumn(),
          buildBlinkInterval(),
          buildEnableBootSound(),
          buildBootSound(),
          buildBlinkSound(),
        ],
      ),
    );
  }

  Widget buildBlinkSound(){
    return Row(
      children: [
        Text('設定閃爍音效'),
        Spacer(),
        DropdownButton(
          value: _bootSound,
          items: [
            DropdownMenuItem<String>(
              child: Text('aaa.mp3'),
              value: '/aaa.mp3',
            ),
            DropdownMenuItem<String>(
              child: Text('bbb.mp3'),
              value: '/bbb.mp3',
            ),
            DropdownMenuItem<String>(
              child: Text('ccc.mp3'),
              value: '/ccc.mp3',
            ),
          ],
          onChanged: _enableBootSound ? (path) {
            setState((){
              _bootSound = path.toString();
            });
          }: null,

          enableFeedback: true,
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }

  Widget buildBootSound() {
    return Row(
      children: [
        Text('設定開機音效'),
        Spacer(),
        DropdownButton(
              value: _bootSound,
              items: [
                DropdownMenuItem<String>(
                  child: Text('aaa.mp3'),
                  value: '/aaa.mp3',
                ),
                DropdownMenuItem<String>(
                  child: Text('bbb.mp3'),
                  value: '/bbb.mp3',
                ),
                DropdownMenuItem<String>(
                  child: Text('ccc.mp3'),
                  value: '/ccc.mp3',
                ),
              ],
              onChanged: _enableBootSound ? (path) {
                      setState((){
                        _bootSound = path.toString();
                      });
                    }: null,

              enableFeedback: true,
              alignment: Alignment.centerRight,
            ),
      ],
    );
  }

  Row buildEnableBootSound() {
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
              _blink = value;
            });
          },
          onChangeEnd: (double value) {
            var cmd = BlinkTimeCommand(_blink.toInt());
            udpManager.write(cmd.bytes);
            logManager.addSendRaw(cmd.bytes, msg: 'SET BLINK', desc: cmd.string);
            prefs?.setDouble('blink', _blink);
          },
          value: _blink,
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
              _volume = value;
            });
          },
          onChangeEnd: (double value) {
            var cmd = VolumeCommand(_volume.toInt());
            udpManager.write(cmd.bytes);
            logManager.addSendRaw(cmd.bytes, msg: 'SET VOLUME', desc: cmd.string);
            prefs?.setDouble('volume', _volume);
          },
          value: _volume,
          min: 0,
          max: 21,
        ),
      ],
    );
  }
}
