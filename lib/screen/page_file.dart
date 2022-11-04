import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTP files'),
        actions: [
          IconButton(
              onPressed: () {
                FtpManager.instance.refreshFiles();
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          const Expanded(
            child: FtpBrowser(),
            flex: 1,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('上傳檔案'),
            subtitle: const Text('找裝置中的檔案'),
            trailing: busy ? const CircularProgressIndicator() : const Icon(Icons.search),
            onTap: () {
              if(state == 2) {
                pickFile();
              }
            }
          ),
        ],
      ),
    );
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
}

class FtpBrowser extends StatefulWidget {
  const FtpBrowser({Key? key}) : super(key: key);

  @override
  State<FtpBrowser> createState() => _FtpBrowserState();
}

class _FtpBrowserState extends State<FtpBrowser> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FTPEntry>>(
        stream: FtpFilesObserver.instance().stream,
        initialData: FtpFilesObserver.instance().getFiles(),
        builder: (context, snapshot) {
          var files = snapshot.data ?? [];
          return state != 2
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: state == 0 ? () {
                          var ssid = SetupOptions.instance.getValue('WiFi_SSID');
                          var pw = SetupOptions.instance.getValue('WiFi_Password');
                          if (ssid != null && pw != null) {
                            connect(ssid, pw);
                          }
                        }: null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(state == 0 ? '連接檔案目錄' : '連接中．．．'),
                        ),
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all(Colors.white),
                            backgroundColor: MaterialStateProperty.all( state == 0 ? Colors.red: Colors.yellow),
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
                      leading: Icon(files[index].type == FTPEntryType.FILE ? Icons.file_copy : Icons.folder),
                      title: Text(utf8Decode(files[index].name)),
                      subtitle: Text(time),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                        ),
                        onPressed: () async {
                          await FtpManager.instance.deleteFile(utf8Decode(files[index].name));
                          FtpManager.instance.refreshFiles();
                        },
                      ),
                    );
                  });
        });
  }

  @override
  void dispose() {
    FtpManager.instance.disconnect();
    WiFiForIoTPlugin.disconnect();
    state = 0;
    super.dispose();
  }

  void connect(String ssid, String pw) async {
    setState(() {
      state = 1;
    });
    var success = await WiFiForIoTPlugin.connect(ssid, password: pw, joinOnce: true, security: NetworkSecurity.WPA)
        .timeout(Duration(seconds: 10), onTimeout: () => false);
    udpManager.isConnected = success;
    if (udpManager.isConnected) {
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
    FtpManager.instance.disconnect();
    WiFiForIoTPlugin.disconnect();
    if (mounted) {
      setState(() {
        state = 0;
      });
    }
  }

  Future bindFtp() async {
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
