class Log{
  DateTime time;
  List<int>? raw;
  int type;
  String? title;
  String? description;
  Log(this.time, this.type, {this.raw, this.title, this.description});
}

class LogType{
  static const event = 0;
  static const sendraw = 10;
  static const receiveraw = 11;
}