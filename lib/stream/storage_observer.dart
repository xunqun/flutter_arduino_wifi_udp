import 'dart:async';

class StorageObserver{
  static var _instance = StorageObserver();
  StreamController<List<String>> _controller = StreamController.broadcast();
  StreamSink<List<String>> get _sink => _controller.sink;
  Stream<List<String>> get stream => _controller.stream;
  List<String> _files = [];
}