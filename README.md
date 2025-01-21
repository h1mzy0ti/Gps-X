# Gps-X
GPS tracker based on ESP12F which uses SIM800 GSM Module and NEO-6MV2 GPS Module for GPS functionality

# Main feature 
1. Detect Engine start (when powered on)
2. Light Sleep Mode
3. Active mode when power is on


# Estiamted runtime for 3.7V 1800 mAH battery and vehicle power
Light Sleep Mode (More Frequent Waking Up)
ESP8266 in Light Sleep: ~0.9mA
SIM800 and GPS active: ~51.5mA (for the GPS and SIM800 modules).
Total Power Consumption: 0.9mA (ESP8266) + 51.5mA (GPS + GSM) = ~52.4mA.
Time Calculation for Light Sleep Mode:
With a 3.7V 1800mAh battery: ≈34.3hours