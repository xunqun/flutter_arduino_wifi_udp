import 'dart:typed_data';

class ByteTool{
  static List<int> stringToListIntWithSize(List<int> bytes, int size) {
    List<int> result = List.filled(size, 0x20);
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i];
    }
    return result;
  }

  static int checkSum(List<int> array) {
    var result = array[0];
    for (int i = 1; i < array.length; i++) {
      result = result ^ array[i];
    }
    return result;
  }

  static List<int> hexStringToIntList(String s){
    if (s.length.isEven) {
      List<int> data = [];
      for (int i = 0; i < s.length; i += 2) {
        data.add(int.parse(s.substring(i, i + 2), radix: 16));
      }
      return data;
    }
    return [];
  }

  static Uint8List int32bytes(int value, int length) {
    var bytes = Uint8List(4)..buffer.asByteData().setInt32(0, value);
    return bytes.sublist(4-length);
  }

}