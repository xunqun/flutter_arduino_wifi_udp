import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wifi_udp/command/outcommand.dart';
import 'package:flutter_wifi_udp/manager/log_manager.dart';
import 'package:flutter_wifi_udp/manager/udp_manager.dart';
import 'package:flutter_wifi_udp/manager/upload_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

var busy = false;

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  var progress = 0;
  double _volume = 20.0;
  double _blink = 600.0;

  @override
  void initState() {
    initValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload file'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('音量'),
              ),
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
                label: '音量',
              ),
              Text('${_volume.toInt()}')
            ],
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('閃爍'),
              ),
              Slider(
                onChanged: (double value) {
                  setState(() {
                    _blink = value;
                  });
                },
                onChangeEnd: (double value){
                  var cmd = BlinkTimeCommand(_blink.toInt());
                  udpManager.write(cmd.bytes);
                  logManager.addSendRaw(cmd.bytes, msg: 'SET BLINK', desc: cmd.string);
                  prefs?.setDouble('blink', _blink);
                },
                value: _blink,
                min: 600,
                max: 850,
                label: '閃爍',
              ),
              Text('${_blink.toInt()}')
            ],
          ),
          Divider(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text('the_mini_vandals.mp3'),
                  subtitle: Text('4.6MB'),
                  trailing: busy
                      ? CircularProgressIndicator()
                      : IconButton(
                          icon: Icon(Icons.send_to_mobile),
                          onPressed: () {
                            setState(() {
                              busy = true;
                            });
                            upload(context, 'assets/the_mini_vandals.mp3', 'mp3');
                          },
                        ),
                ),
                ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text('levelup.wav'),
                  subtitle: Text('136KB'),
                  trailing: busy
                      ? CircularProgressIndicator()
                      : IconButton(
                          icon: Icon(Icons.send_to_mobile),
                          onPressed: () {
                            setState(() {
                              busy = true;
                            });

                            upload(context, 'assets/levelup.wav', 'wav');
                          },
                        ),
                ),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('android.png'),
                  subtitle: Text('2KB'),
                  trailing: busy
                      ? CircularProgressIndicator()
                      : IconButton(
                          icon: Icon(Icons.send_to_mobile),
                          onPressed: () {
                            setState(() {
                              busy = true;
                            });
                            upload(context, 'assets/android.png', 'png');
                          },
                        ),
                ),
                ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('其他檔案'),
                  subtitle: Text('找裝置中的檔案'),
                  trailing: busy
                      ? CircularProgressIndicator()
                      : IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            pickFile();
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ProgressDialog? pd;

  void upload(BuildContext context, String path, String ext) async {
    pd = ProgressDialog(context: context);
    pd!.show(
      max: 100,
      msg: "傳送中...",
      progressType: ProgressType.valuable,
    );
    ByteData data = await rootBundle.load(path);
    await uploadManager.startTask(data.buffer.asInt8List(), ext, returnsAFunction());
    pd?.close();
    setState(() {
      busy = false;
    });
  }

  Function(int) returnsAFunction() => (int x) {
        pd?.update(value: x);
      };

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      pd = ProgressDialog(context: context);
      pd!.show(
        max: 100,
        msg: "傳輸中...",
        progressType: ProgressType.valuable,
      );
      setState(() {
        busy = true;
      });
      var platformfile = result.files.single;
      await uploadManager.startTask(
          platformfile.bytes!.toList(growable: false), platformfile.extension!, returnsAFunction());
      pd?.close();
      setState(() {
        busy = false;
      });
    } else {
      // User canceled the picker
    }
  }

  SharedPreferences? prefs;
  initValue() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs?.getDouble('volume') ?? 20.0;
      _blink = prefs?.getDouble('blink') ?? 600.0;
    });
  }
}
