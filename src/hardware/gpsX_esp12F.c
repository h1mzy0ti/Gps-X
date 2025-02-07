/*
This code is written for Esp12f Esp8266 board,
Responsible for communication with the centralized
remote server for updating coordinates that will
reflect on the app (IOS/Android)
2025 @ Himjyoti
*/

// This code manages real-time GPS data, GSM internet communication, and app requirements
#include <SoftwareSerial.h>
#include <TinyGPS++.h>
#include <ArduinoJson.h>

// Hardware Serial Ports
#define RX_PIN 4  // GPS RX
#define TX_PIN 5  // GPS TX
#define GSM_RX 13 // GSM RX
#define GSM_TX 15 // GSM TX

// Global Objects
TinyGPSPlus gps;
SoftwareSerial gpsSerial(RX_PIN, TX_PIN);  // GPS Module
SoftwareSerial gsmSerial(GSM_RX, GSM_TX); // GSM Module

// Server Details
const char* server = "SERVER_IP";
const int port = 8080; // Replace if Different
 
// Battery Monitoring
#define BATTERY_PIN A0        // Battery voltage input pin
#define CHARGING_PIN D2       // Pin to detect charging (e.g., from TP4056 module)

// Voltage reference for full battery (for Li-ion, full charge is 4.2V)
#define FULL_VOLTAGE 4.2
#define EMPTY_VOLTAGE 3.2

// Function Prototypes
void initializeGSM();
void sendToServer(float latitude, float longitude, float battery, const char* status);
void sendSMS(const char* message);
void handleAntiTheft(float latitude, float longitude);
void trackIgnition(bool isOn);
void logCoordinates(float latitude, float longitude, const char* mode);

// Global variable for storing phone number
String smsRecipient;

void setup() {
  Serial.begin(115200);
  gpsSerial.begin(9600);
  gsmSerial.begin(9600);

  initializeGSM();
  pinMode(BATTERY_PIN, INPUT);
  pinMode(CHARGING_PIN, INPUT);  // Set the charging pin as input
  smsRecipient = "+0000000000"; // Default number, can be updated via server/app
  Serial.println("Setup Complete");
}

void loop() {
  // Read GPS data
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());

    if (gps.location.isUpdated()) {
      float latitude = gps.location.lat();
      float longitude = gps.location.lng();
      float batteryLevel = getBatteryLevel();
      bool charging = isCharging();
      int batteryPercentage = getBatteryPercentage(batteryLevel);

      Serial.printf("Lat: %f, Lon: %f, Battery: %fV, Battery Percentage: %d%%, Charging: %s\n", 
                    latitude, longitude, batteryLevel, batteryPercentage, charging ? "Yes" : "No");

      sendToServer(latitude, longitude, batteryLevel, "active");
      logCoordinates(latitude, longitude, "active");
      handleAntiTheft(latitude, longitude);

      delay(5000); // Reduce frequency to conserve battery
    }
  }
}

// Function to get battery voltage
float getBatteryLevel() {
  int raw = analogRead(BATTERY_PIN);
  float voltage = (raw / 1023.0) * 3.3 * 2; // Assuming a voltage divider for 2x scaling
  return voltage;
}

// Function to detect if battery is charging (using charging detection pin)
bool isCharging() {
  return digitalRead(CHARGING_PIN) == HIGH;  // If CHG pin is HIGH, it's charging
}

// Function to calculate battery percentage based on voltage
int getBatteryPercentage(float voltage) {
  if (voltage >= FULL_VOLTAGE) return 100;
  if (voltage <= EMPTY_VOLTAGE) return 0;
  
  // Calculate percentage between 3.2V and 4.2V
  return (int)((voltage - EMPTY_VOLTAGE) / (FULL_VOLTAGE - EMPTY_VOLTAGE) * 100);
}

void initializeGSM() {
  gsmSerial.println("AT");
  delay(1000);
  gsmSerial.println("AT+SAPBR=3,1,\"CONTYPE\",\"GPRS\""); // Set connection type to GPRS
  delay(1000);
  gsmSerial.println("AT+SAPBR=3,1,\"APN\",\"your_apn_here\""); // Set your APN
  delay(1000);
  gsmSerial.println("AT+SAPBR=1,1"); // Open GPRS context
  delay(2000);
  gsmSerial.println("AT+HTTPINIT"); // Initialize HTTP service
  delay(1000);
  Serial.println("GSM Initialized");
}

void sendToServer(float latitude, float longitude, float battery, const char* status) {
  gsmSerial.println("AT+HTTPPARA=\"CID\",1");
  delay(1000);
  gsmSerial.println("AT+HTTPPARA=\"URL\",\"http://" + String(server) + ":" + String(port) + "/update\"");
  delay(1000);

  DynamicJsonDocument json(256);
  json["latitude"] = latitude;
  json["longitude"] = longitude;
  json["battery"] = battery;
  json["status"] = status;

  // Update SMS recipient if new number is provided
  if (json.containsKey("smsRecipient")) {
    smsRecipient = String((const char*)json["smsRecipient"]);
  }

  String postData;
  serializeJson(json, postData);

  gsmSerial.println("AT+HTTPDATA=" + String(postData.length()) + ",10000");
  delay(1000);
  gsmSerial.print(postData);
  delay(1000);
  gsmSerial.println("AT+HTTPACTION=1"); // POST request
  delay(5000);
  gsmSerial.println("AT+HTTPTERM"); // Terminate HTTP session
  delay(1000);
  Serial.println("Data sent to server");
}

void sendSMS(const char* message) {
  gsmSerial.println("AT+CMGF=1"); // Set SMS to Text Mode
  delay(1000);
  gsmSerial.print("AT+CMGS=\"");
  gsmSerial.print(smsRecipient);
  gsmSerial.println("\"");
  delay(1000);
  gsmSerial.print(message);
  delay(1000);
  gsmSerial.write(26); // Ctrl+Z to send SMS
  Serial.println("SMS sent");
}

void handleAntiTheft(float latitude, float longitude) {
  static bool theftAlert = false;

  if (!theftAlert && latitude != 0.0 && longitude != 0.0) { // Replace with actual conditions
    sendSMS("Alert: Unauthorized movement detected!");
    theftAlert = true;
  }
}

void trackIgnition(bool isOn) {
  if (isOn) {
    Serial.println("Ignition On");
  } else {
    Serial.println("Ignition Off");
  }
}

void logCoordinates(float latitude, float longitude, const char* mode) {
  Serial.printf("Logging: Lat: %f, Lon: %f, Mode: %s\n", latitude, longitude, mode);
  // Add SD card or EEPROM storage logic here
}
