import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wifi_udp/manager/upload_manager.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

var busy = false;

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  var progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload file'),
      ),
      body: ListView(
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
}
