import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wifi_udp/manager/ftp_manager.dart';
import 'package:flutter_wifi_udp/utility/string_tool.dart';
import 'package:intl/intl.dart';
import 'package:ftpconnect/src/dto/ftp_entry.dart';

import '../stream/ftp_observer.dart';

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
            onTap: busy
                ? null
                : () {
                    pickFile();
                  },
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
          return files.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('沒有檔案'),
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
                        icon: const Icon(Icons.close, size: 18,),
                        onPressed: () async {
                          await FtpManager.instance.deleteFile(utf8Decode(files[index].name));
                          FtpManager.instance.refreshFiles();
                        },
                      ),
                    );
                  });
        });
  }
}
