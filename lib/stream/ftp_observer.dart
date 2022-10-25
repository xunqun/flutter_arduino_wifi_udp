import 'dart:async';
import 'package:ftpconnect/src/dto/ftp_entry.dart';

class FtpFilesObserver{
  static FtpFilesObserver? _instance;
  StreamController<List<FTPEntry>> _ftpFilesController = StreamController();
  StreamSink<List<FTPEntry>> get _sink => _ftpFilesController.sink;
  Stream<List<FTPEntry>> get stream => _ftpFilesController.stream;
  List<FTPEntry> _files = [];
  FtpFilesObserver(){

  }

  static FtpFilesObserver instance(){
    if(_instance == null){
      _instance = FtpFilesObserver();
    }
    return _instance!;
  }

  setFiles(List<FTPEntry> list){
    _files = list;
    _sink.add(list);
  }

  getFiles() => _files;
  close() {
    _ftpFilesController.close();
    _instance = null;
  }
}