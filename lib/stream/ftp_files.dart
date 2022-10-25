import 'dart:async';
import 'package:ftpconnect/src/dto/ftp_entry.dart';

class FtpFiles{
  static final StreamController<List<FTPEntry>> _ftpFilesController = StreamController();
  static StreamSink<List<FTPEntry>> get _ftpFilesSink => _ftpFilesController.sink;
  static Stream<List<FTPEntry>> get ftpFilesStream => _ftpFilesController.stream;
  static List<FTPEntry> _files = [];

  static setFiles(List<FTPEntry> list){
    _files = list;
    _ftpFilesSink.add(list);
  }

  static getFiles() => _files;
}