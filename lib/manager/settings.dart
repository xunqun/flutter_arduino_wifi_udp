import 'package:flutter/cupertino.dart';
import 'package:flutter_wifi_udp/utility/byte_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';

Settings settings = Settings();
class Settings extends ChangeNotifier{
  SharedPreferences? pref;
  Settings(){
    init();
  }

  init() async{
    pref = await SharedPreferences.getInstance();
  }

  String get beginByteString{
    return pref?.getString('beginByte') ?? 'AABB';
  }

  List<int> get beginByte{
    String? hexString = pref?.getString('beginByte');
    return hexString != null ? ByteTool.hexStringToIntList(hexString) : [0xAA, 0xBB];
  }

  set beginByte(value){
    pref?.setString('beginByte', value);
    notifyListeners();
  }

  String get endByteString{
    return pref?.getString('endByte') ?? 'CCDD';
  }

  List<int> get endByte{
    String? hexString = pref?.getString('endByte');
    return hexString != null ? ByteTool.hexStringToIntList(hexString) : [0xCC, 0xDD];
  }

  set endByte(value){
    pref?.setString('endByte', value);
    notifyListeners();
  }

  String get startWord{
    String? startWord = pref?.getString('startWord');
    return startWord ?? 'Download';
  }

  set startWord(value){
    pref?.setString('startWord', value);
    notifyListeners();
  }

  String get endWord{
    String? startWord = pref?.getString('endWord');
    return startWord ?? 'End';
  }

  set endWord(value){
    pref?.setString('endWord', value);
    notifyListeners();
  }

  int get dataLength{
    // return pref?.getInt('dataLength') ?? 253;
    return pref?.getInt('dataLength') ?? 253;
  }

  set dataLength(int value){
    pref?.setInt('dataLength', value);
    notifyListeners();
  }

  int get transInterval{
    return pref?.getInt('transInterval') ?? 10;
  }

  set transInterval(int value){
    pref?.setInt('transInterval', value);
    notifyListeners();
  }

}