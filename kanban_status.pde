#include <Ethernet.h>
#include <WString.h>

int red = 6;
int yellow = 7;
int green = 8;

byte mac[] = { 0x00, 0x26, 0x4a, 0x14, 0x7F, 0x9F };
byte ip[] = { 192,168,3,222 };
byte server[] = { 192,168,3,15 }; // kanban

#define maxResponseLength 1000

String response = String(maxResponseLength);

int notConnectedMode = 0;
int connectedMode = 1;
int mode = 0;

int pingInterval = 10 * 1000; //10 seconds
long maxLightOnTime = 60000; //1 minute

unsigned long lastPingTime = 0;
unsigned long lastBuild = 0;

int currentLight = yellow;

Client client(server, 8080);

void setup()
{  
  pinMode(red, OUTPUT);
  pinMode(yellow, OUTPUT);
  pinMode(green, OUTPUT);
  delay(500);
  Ethernet.begin(mac, ip);
//  Serial.begin(9600);
  delay(500);
}

void loop()
{
  
  watchBuildStateTimeout();
  
  if((millis() - lastPingTime) >= pingInterval){
    checkHudson(); 
  } else {
    flashIfBuilding();
  }   
}

void flashIfBuilding() {
 if((currentLight == yellow) && (mode == notConnectedMode)) {
    digitalWrite(currentLight, HIGH);
    delay(1000);
    digitalWrite(currentLight, LOW);
    delay(1000);
    lastBuild = millis(); 
//    Serial.println("current Light is Building");
  }  
}

void watchBuildStateTimeout() {
  if((currentLight != yellow) && (mode == notConnectedMode)) {
    if(
    ((millis() - lastBuild) >= maxLightOnTime) && (currentLight != red)) {
      digitalWrite(currentLight, LOW);
//      Serial.println("current Light is OFF");
    }
    else {
      digitalWrite(currentLight, HIGH);
//      Serial.println("current Light is ON");
    }
  }
}


void checkHudson(){
   if(mode == notConnectedMode){
    // try to connect
//     Serial.println("connecting...");
    if (client.connect()) {
//      Serial.println("connected");
      client.println("GET /api/xml?xpath=//job/name[.='office-kitten-multi-threaded']/following-sibling::color HTTP/1.0");
      client.println();
      mode = connectedMode;
    } 
    else {
//      Serial.println("connection failed");
      delay(2000);
//      Serial.println("trying again...");  
    }
   
  } 
  // in connectedMode 
  else { 
    if (client.available()) {
      char c = client.read();
      Serial.print(c);
      response.append(c);
    }

    if (!client.connected()) {
      lastPingTime = millis();
      
      if(response.contains("anime")){
//          Serial.println("YELLOW - 412");
          currentLight = yellow;
          digitalWrite(red, LOW);
          digitalWrite(green, LOW);
      }
      else if(response.contains("<color>red</color>") || response.contains("<color>aborted</color>")) {
//        Serial.println("RED - 412");
        currentLight = red;
        digitalWrite(yellow, LOW);
        digitalWrite(green, LOW);
      } 
      else if(response.contains("<color>blue</color>")){
//        Serial.println("GREEN - 200");
        currentLight = green;
        digitalWrite(red, LOW);
        digitalWrite(yellow, LOW);
      }
//      Serial.println();
//      Serial.println("disconnecting.");
      client.stop();

      response = "";
      mode = notConnectedMode;
      delay(500);
    }
  }

}
