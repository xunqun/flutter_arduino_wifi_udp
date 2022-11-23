import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/command/incommand.dart';
import 'package:flutter_wifi_udp/command/outcommand.dart';
import 'package:flutter_wifi_udp/manager/ble_manager.dart';
import 'package:flutter_wifi_udp/manager/ftp_manager.dart';
import 'package:flutter_wifi_udp/manager/setup_options.dart';
import 'package:flutter_wifi_udp/utility/string_tool.dart';
import 'package:intl/intl.dart';
import 'package:ftpconnect/src/dto/ftp_entry.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../manager/udp_manager.dart';
import '../stream/ftp_observer.dart';

var busy = false;
int state = 0; // 0: idle, 1: busy ,2: ftp connected

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  var progress = 0;

  StreamSubscription<Map<String, dynamic>>? subs;

  StreamSubscription<InCommand>? inCmdSubs = null;

  @override
  void initState() {
    super.initState();

    inCmdSubs = BleManager.instance.inCmdStream.listen((event) {
      if (event.runtimeType == ReceivedWifiTimeout) {
        setState(() {
          state = 0;
        });
      }

      if (event.runtimeType == ReceivedWiFiStatus) {
        if ((event as ReceivedWiFiStatus).value == 0) {
          setState(() {
            state = 0;
          });
        }
      }
    });

    if (SetupOptions.instance.getWifiStatus() == 0) {
      setState(() {
        state = 0;
      });
    }
  }

  @override
  void dispose() {
    // subs?.cancel();
    super.dispose();
    inCmdSubs?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTP files'),
        actions: [
          IconButton(
              onPressed: () {
                handleConnect();
              },
              icon: Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [Icon(Icons.info), Text('長按檔案項目以開啟操作列表')],
            ),
          ),
          Expanded(
            child: FtpBrowser(connectCallback: handleConnect),
            flex: 1,
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('上傳檔案'),
              subtitle: const Text('找裝置中的檔案'),
              trailing: busy ? const CircularProgressIndicator() : const Icon(Icons.search),
              onTap: () {
                if (state == 2) {
                  pickFile();
                }
              }),
        ],
      ),
    );
  }

  void handleConnect() {
    var ssid = SetupOptions.instance.getValue('WiFi_SSID');
    var pw = SetupOptions.instance.getValue('WiFi_Password');
    if (ssid != null && pw != null) {
      connect(ssid, pw);
    }
  }

  void upload(BuildContext context, String path, String ext) async {
    await FtpManager.instance.upload(path);
    setState(() {
      busy = false;
    });
    FtpManager.instance.refreshFiles();
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      setState(() {
        busy = true;
      });
      var path = result.files.single.path;
      if (path != null) {
        await FtpManager.instance.upload(path);
      }
      setState(() {
        busy = false;
      });
      FtpManager.instance.refreshFiles();
    }
  }

  void connect(String ssid, String pw) async {
    disconnect();
    BleManager.instance.sendCommand(SetWifiStatusCommand(true));
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      state = 1;
    });
    var success = await WiFiForIoTPlugin.connect(ssid, password: pw, joinOnce: true, security: NetworkSecurity.WPA)
        .timeout(const Duration(seconds: 10), onTimeout: () => false);
    print('connect wifi -> $ssid ($pw)');
    wifiManager.isConnected = success;
    if (wifiManager.isConnected) {
      WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(seconds: 1));
      await bindFtp();
    } else {
      setState(() {
        state = 0;
      });
    }
  }

  void disconnect() {
    try {
      FtpManager.instance.disconnect();
      WiFiForIoTPlugin.disconnect();
      if (mounted) {
        setState(() {
          state = 0;
        });
      }
    } catch (e) {}
  }

  Future bindFtp() async {
    Future.delayed(Duration(seconds: 6)).then((value){
        if(state == 1){
          setState(() {
            state = 0;
          });
        }});
    var success = await FtpManager.instance.connect().timeout(const Duration(seconds: 6), onTimeout: () => false) ?? false;
    setState(() {
    state = success ? 2 : 0;
    });
    if (success) {
    try {
    await FtpManager.instance.refreshFiles();
    } catch (e) {
    print(e.toString());
    }
    }
  }
}

class FtpBrowser extends StatefulWidget {
  final VoidCallback? connectCallback;

  const FtpBrowser({Key? key, this.connectCallback}) : super(key: key);

  @override
  State<FtpBrowser> createState() => _FtpBrowserState();
}

class _FtpBrowserState extends State<FtpBrowser> {
  AlertDialog? actionsDialog;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FTPEntry>>(
        stream: FtpFilesObserver
            .instance()
            .stream,
        initialData: FtpFilesObserver.instance().getFiles(),
        builder: (context, snapshot) {
          var files = snapshot.data ?? [];
          files = files.where((element) => !element.name.startsWith(('.'))).toList();
          return state != 2
              ? Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: state == 0
                      ? () {
                    if (widget.connectCallback != null) {
                      widget.connectCallback!();
                    }
                  }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(state == 0 ? 'Wifi開關' : '連接中．．．'),
                  ),
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor: MaterialStateProperty.all(state == 0 ? Colors.red : Colors.amber),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36.0),
                          side: const BorderSide(color: Colors.white)))),
                ),
              ],
            ),
          )
              : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                var time = DateFormat('yyyy/MM/dd HH:mm:ss').format(files[index].modifyTime!);
                return ListTile(
                  leading: Icon(files[index].name.contains('mp3') ? Icons.music_note : Icons.file_copy),
                  title: Text(utf8Decode(files[index].name)),
                  subtitle: Text(time),
                  onTap: () {
                    if (files[index].name.contains('mp3')) {
                      playSound(files[index]);
                    }
                  },
                  onLongPress: () {
                    if (files[index].name.contains('mp3')) {
                      showActionsDialog(files[index]);
                    }
                  },
                );
              });
        });
  }

  @override
  void dispose() {
    // FtpManager.instance.disconnect();
    // WiFiForIoTPlugin.disconnect();
    // state = 0;
    super.dispose();
  }

  void playSound(FTPEntry file) {
    var cmd = AskPlaySoundCommand(utf8Decode(file.name));
    BleManager.instance.sendCommand(cmd);
  }

  void showActionsDialog(FTPEntry file) {
    showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            content: Container(
              width: 300,
              height: 200,
              child: ListView(
                children: [
                  // TextButton(
                  //     onPressed: () {
                  //       var cmd = AskPlaySoundCommand(utf8Decode(file.name));
                  //       BleManager.instance.sendCommand(cmd);
                  //       Navigator.pop(context);
                  //     },
                  //     child: Text('播放')),
                  TextButton(
                      onPressed: () {
                        var cmd = SetBootSoundCommand(true, utf8Decode(file.name));
                        BleManager.instance.sendCommand(cmd);
                        Navigator.pop(context);
                      },
                      child: Text('設為開機音效')),
                  TextButton(
                      onPressed: () {
                        var cmd = SetBlinkSoundCommand(true, utf8Decode(file.name));
                        BleManager.instance.sendCommand(cmd);
                        Navigator.pop(context);
                      },
                      child: Text('設為閃爍音效')),
                  TextButton(
                      onPressed: () {
                        FtpManager.instance.deleteFile(utf8Decode(file.name));
                        Navigator.pop(context);
                      },
                      child: Text('刪除')),
                ],
              ),
            ),
          );
        });
  }
}
