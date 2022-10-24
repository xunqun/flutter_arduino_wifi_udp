import 'package:flutter/widgets.dart';
import 'package:ftpconnect/ftpconnect.dart';

class FtpManager extends ChangeNotifier {
  static var instance = FtpManager();
  final _address = '192.168.4.1';
  final _port = 21;
  final _user = 'KOSO';
  final _password = '0000';
  FTPConnect? ftpConnect;

  Future<bool?> connect() async {
    ftpConnect = FTPConnect(_address, user: _user, pass: _password, port: _port, timeout: 30, debug: true);
    ftpConnect!.listCommand = ListCommand.LIST;
    return await ftpConnect?.connect();
  }

  Future<bool?> disconnect() async{
    return ftpConnect?.disconnect();
  }

  listFiles() => ftpConnect?.listDirectoryContentOnlyNames();
  mkdir() => ftpConnect?.makeDirectory('test');
  deleteDirectory() => ftpConnect?.deleteDirectory('test');
  currentDirectory() => ftpConnect?.currentDirectory();

}