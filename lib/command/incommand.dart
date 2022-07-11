class AckCommand{
  var complete = 0; // byte3, 0未完成接收,1完成接收
  var resendRequired = 0; // byte5, 0不需要重傳 1需要重傳
  var filetype = 0;
  var dlc = 0;
  var count = 0;
  var checksum = 0;
  var finished = 0;
  
  AckCommand(List<int> raw){
    complete = raw[3];
    resendRequired = raw[5];
    filetype = raw[6];
    dlc = raw[7];
    count = raw[8];
    checksum = raw[9];
    finished = raw[10];
  }
}