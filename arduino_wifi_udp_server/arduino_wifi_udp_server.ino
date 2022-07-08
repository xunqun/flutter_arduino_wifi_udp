#include <WiFi.h>
#include "AsyncUDP.h"

AsyncUDP udp;

char packetBuffer[255];

unsigned int localPort = 1234;

const char *ssid = "HiAp";  
const char *password = "BB9ESERVER";

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(115200);
  WiFi.softAP(ssid, password);  // ESP-32 as access point
//  Udp.begin(localPort);
 if(udp.listen(1234)) {
  Serial.print("UDP Listening on IP: ");
        digitalWrite(LED_BUILTIN, HIGH);digitalWrite(LED_BUILTIN, HIGH);
        Serial.println(WiFi.localIP());
        udp.onPacket([](AsyncUDPPacket packet) {
            digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
            delay(10);
            Serial.print("UDP Packet Type: ");
            Serial.print(packet.isBroadcast()?"Broadcast":packet.isMulticast()?"Multicast":"Unicast");
            Serial.print(", From: ");
            Serial.print(packet.remoteIP());
            Serial.print(":");
            Serial.print(packet.remotePort());
            Serial.print(", To: ");
            Serial.print(packet.localIP());
            Serial.print(":");
            Serial.print(packet.localPort());
            Serial.print(", Length: ");
            Serial.print(packet.length());
            Serial.print(", Data: ");
            Serial.write(packet.data(), packet.length());
            Serial.println();
            //reply to the client
            packet.printf("Got %u bytes of data", packet.length());
                     // wait for a second
            digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
            delay(10);               

        });
 }
}

void loop() {
//
//   delay(1000);
//   udp.broadcast("Anyone here?");

}
