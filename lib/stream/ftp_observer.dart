import 'dart:async';
import 'package:ftpconnect/src/dto/ftp_entry.dart';

class FtpFilesObserver{
  static FtpFilesObserver? _instance;
  StreamController<List<FTPEntry>> _controller = StreamController.broadcast();
  StreamSink<List<FTPEntry>> get _sink => _controller.sink;
  Stream<List<FTPEntry>> get stream => _controller.stream;
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

  List<FTPEntry> getFiles() => _files;
  close() {
    _controller.close();
    _instance = null;
  }
}