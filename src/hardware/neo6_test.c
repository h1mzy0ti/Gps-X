#include <TinyGPS++.h>
#include <SoftwareSerial.h>

TinyGPSPlus gps;

// Set up software serial for NodeMCU, using GPIO 4 for RX and GPIO 5 for TX
SoftwareSerial ss(4, 5); // RX, TX pins connected to NEO-6M

void setup() {
  // Start the serial communication
  Serial.begin(115200);  // For debugging
  ss.begin(9600);        // Start communication with GPS module at 9600 baud rate
  
  Serial.println("GPS Check: Starting...");
}

void loop() {
  while (ss.available() > 0) {
    char c = ss.read();  // Read one byte at a time
    Serial.write(c);     // Output the raw GPS data to the Serial Monitor
    gps.encode(c);       // Feed the byte to the TinyGPS++ library
  }

  // If GPS data is available, print the location
  if (gps.location.isUpdated()) {
    Serial.print("Latitude= "); 
    Serial.print(gps.location.lat(), 6);
    Serial.print(" Longitude= ");
    Serial.println(gps.location.lng(), 6);
  }
  
  // If no GPS signal, print a message
  if (!gps.location.isUpdated()) {
    Serial.println("Detecting signal.");
  }

  delay(1000); // Wait for 1 second before the next iteration
}
