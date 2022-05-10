#include <WiFi.h>
#include <WiFiUdp.h>

WiFiUDP Udp; // Creation of wifi Udp instance

char packetBuffer[255];

unsigned int localPort = 1234;

const char *ssid = "HiAp";  
const char *password = "BB9ESERVER";

void setup() {
  Serial.begin(115200);
  WiFi.softAP(ssid, password);  // ESP-32 as access point
  Udp.begin(localPort);
}

void loop() {
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    int len = Udp.read(packetBuffer, 255);
    if (len > 0) packetBuffer[len-1] = 0;
    Serial.print("Recibido(IP/Size/Data): ");
    Serial.print(Udp.remoteIP());
    Serial.print(" / ");
    Serial.print(packetSize);
    Serial.print(" / ");
    Serial.println(packetBuffer);

    Udp.beginPacket(Udp.remoteIP(),Udp.remotePort());
    Udp.printf("received: ");
    Udp.printf(packetBuffer);
    Udp.printf("\r\n");
    Udp.endPacket();
  }
  delay(2000);

  Udp.beginPacket(Udp.remoteIP(),Udp.remotePort());
  Udp.printf("hello from server ");
  Udp.endPacket();
}
