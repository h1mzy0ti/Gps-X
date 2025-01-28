# Gps-X
<p align="center">
  <img src="image/logo.png" width="200"/>
</p>
GPS tracker based on ESP12F which uses SIM800 GSM Module and NEO-6MV2 GPS Module for GPS functionality.

This GPS tracker project is designed to provide comprehensive vehicle tracking and monitoring solutions. It leverages GPS and GSM modules integrated with an ESP-12F ESP8266 microcontroller, enabling real-time updates, data logging, and multiple alert mechanisms. The tracker is suitable for cars, ensuring power efficiency and enhanced security features.

---
### Interface

Below is a screenshot showing the interface of the app:

![Interface](image/GpsX%20mockup.png)

---

### Main Features

1. **Real-Time Coordinates to Server**
   - Sends real-time GPS coordinates to a self-hosted server.
   - Displays the vehicle's current location on a mobile app.

2. **Engine and Mode Indication**
   - **Engine On Indication:** Shows when the vehicle's power (engine) is on.
   - **Mode Indication:**
     - **Active Mode:** Vehicle power is on, and the tracker operates in full functionality.
     - **Light Sleep Mode:** Tracker operates on battery power with reduced activity to save energy.

3. **GPS Coordinate Logs**
   - Logs GPS coordinates for both Active and Light Sleep modes.
   - Retains data for 7 days and auto-deletes older logs.

4. **SMS Alerts for Location Departure**
   - Sends SMS notifications if the vehicle exits predefined locations such as Home or Office.

5. **Anti-Theft Mode**
   - Activates via the mobile app to monitor unauthorized movement of the vehicle.
   - Sends alerts if the vehicle moves without authorization.

6. **Battery Health Monitoring**
   - Tracks and displays the tracker’s battery voltage level in the mobile app.
   - Includes overcharging protection when connected to vehicle power.

7. **Historical Route Playback**
   - Allows users to view the vehicle’s route history for specific dates via the mobile app.

---

### Software Features

#### Mobile App:
- View real-time vehicle location.
- Mark locations as Home, Office, or Other.
- Enable/Disable Anti-Theft Mode.
- View battery status and historical routes.

#### Server Integration:
- Receives and logs GPS data.
- Stores 7-day GPS logs for route playback.
- Sends commands to the tracker for OTA updates and alert configurations.

---

### Estimated Runtime for 3.7V 1800mAh Battery and Vehicle Power

**Light Sleep Mode (More Frequent Waking Up)**
- ESP8266 in Light Sleep: ~0.9mA
- SIM800 and GPS active: ~51.5mA (for the GPS and SIM800 modules).
- Total Power Consumption: 0.9mA (ESP8266) + 51.5mA (GPS + GSM) = ~52.4mA.

**Time Calculation for Light Sleep Mode:**
- With a 3.7V 1800mAh battery: ≈34.3 hours

---

### Contribution

Feel free to fork this repository, create issues, or submit pull requests to contribute to this project.
