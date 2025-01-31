/*
This code is written for Esp12f Esp8266 board,
Responsible for communication with the centralized
remote server for updating coordinates that will
reflect on the app (IOS/Android). This code uses
Wi-Fi to connect to the internet serving as a test code
2025 @ Himjyoti
*/

// This code manages real-time GPS data, Wi-Fi communication, and app requirements
#include <SoftwareSerial.h>
#include <TinyGPS++.h>
#include <ArduinoJson.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>

// Hardware Serial Ports
#define RX_PIN 4  // GPS RX
#define TX_PIN 5  // GPS TX
const String DEVICE_ID = "STATIC_DEVICE_ID"; // Replace with your desired static device ID

// Global Objects
TinyGPSPlus gps;
SoftwareSerial gpsSerial(RX_PIN, TX_PIN);  // GPS Module

// Server Details
const char* ssid = "YOUR_SSID";         // Your Wi-Fi SSID
const char* password = "YOUR_PASSWORD"; // Your Wi-Fi password
const char* server = "SERVER_IP";       // Your server IP address or domain
const int port = 8080;                  // Your server port, change if necessary

// Battery Monitoring
#define BATTERY_PIN A0        // Battery voltage input pin
#define CHARGING_PIN D2       // Pin to detect charging (e.g., from TP4056 module)

// Voltage reference for full battery (for Li-ion, full charge is 4.2V)
#define FULL_VOLTAGE 4.2
#define EMPTY_VOLTAGE 3.2

// Function Prototypes
void sendToServer(float latitude, float longitude, float battery, const char* status);
void logCoordinates(float latitude, float longitude, const char* mode);

// Global variable for storing phone number (if needed for SMS)
String smsRecipient;

void setup() {
  Serial.begin(115200);
  gpsSerial.begin(9600);

  // Connect to Wi-Fi
  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting...");
  }
  Serial.println("Wi-Fi Connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

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

void sendToServer(float latitude, float longitude, float battery, const char* status) {
  HTTPClient http;
  String url = "http://" + String(server) + ":" + String(port) + "/add_data"; // Your server URL
  http.begin(url); // Specify the URL

  // Prepare the JSON payload
  DynamicJsonDocument json(256);
  json["latitude"] = latitude;
  json["longitude"] = longitude;
  json["battery"] = battery;
  json["status"] = status;

  String postData;
  serializeJson(json, postData);

  http.addHeader("Content-Type", "application/json"); // Set content type to JSON
  int httpResponseCode = http.POST(postData); // Send POST request

  if (httpResponseCode > 0) {
    Serial.println("Data sent successfully");
  } else {
    Serial.printf("Error sending data: %d\n", httpResponseCode);
  }

  http.end(); // Close the HTTP connection
}

void logCoordinates(float latitude, float longitude, const char* mode) {
  Serial.printf("Logging: Lat: %f, Lon: %f, Mode: %s\n", latitude, longitude, mode);
  // You can implement saving this data to an SD card or EEPROM if needed
}
