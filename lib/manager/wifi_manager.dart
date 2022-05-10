
import 'package:flutter/cupertino.dart';

UdpManager udpManager = UdpManager();
class UdpManager extends ChangeNotifier{
  /// Target AP connect state
  bool _isConnected = false;
  set isConnected(value){
    _isConnected = value;
    notifyListeners();
  }
  get isConnected => _isConnected;

  write(List<int> data ){

  }

  disconnect(){

  }
}