

import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ftpconnect/src/dto/ftp_entry.dart';
import '../stream/ftp_observer.dart';

class FtpManager {
  static var instance = FtpManager();
  final _address = '192.168.4.1';
  final _port = 21;
  final _user = 'KOSO';
  final _password = '0000';
  FTPConnect? ftpConnect;
  List<FTPEntry> _files = [];

  Future<bool?> connect() async {
    ftpConnect = FTPConnect(_address, user: _user, pass: _password, port: _port, timeout: 30, debug: true);
    ftpConnect!.listCommand = ListCommand.LIST;
    return await ftpConnect?.connect();
  }

  Future<bool?> disconnect() async{
    FtpFilesObserver.instance().close();
    return ftpConnect?.disconnect();

  }

  refreshFiles() {
    ftpConnect?.listDirectoryContent().then((value) {
      _files = value;
      FtpFilesObserver.instance().setFiles(value);
    });
  }

  List<FTPEntry> getFiles() => _files;

  mkdir() => ftpConnect?.makeDirectory('test');
  deleteDirectory(String path) => ftpConnect?.deleteDirectory(path);
  deleteFile(String path) => ftpConnect?.deleteFile(path);
  currentDirectory() => ftpConnect?.currentDirectory();
  Future<bool>? download(String remotePath, String localPath) => ftpConnect?.downloadFileWithRetry(remotePath, File(localPath));
  Future<bool>? upload(String uploadPath) => ftpConnect?.uploadFileWithRetry(File(uploadPath));
}