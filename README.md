# Domoticz-Heatpump-Thermostat
Thermostat for domoticz using ESP 8266 and EasyESP as hardware

Requirements : 
ESP8266 with ÈSP Easy installed
ESP Easy  can have the following devices used by the thermostat : PIR, DHT22 (temperature and humidity), IR (with HeatPumpIR plugin)

Dummy devices in DOMOTICZ :
Temperature,
Selector, 
Second selector for managing plannings, Room-Auto-Cal
Thermostat Thermostat, 
Third Selector ACModeRoom for calling ESP Easy

Variable created in Domoticz

All these dummy devices and IPs can be modified with local variables in the begining of the script ThermostatRoom

Thermostat code given by two LUA Scripts:
ACRoom -> manage ESP Easy with Third Selector ACModeRoom and Thermostat
ThermostatRoom -> code of the Thermostat

Features:
Several modes: Frost, Eco, Comfort, Forced (choose your temperature with thermostat) and Auto
Mode Auto uses Calendar defined with Dummy Selector Room-auto-Cal
Stop Heatpump if temperature over a given threshold
Start Heatpump if temperature below a given threshold
Uses PIR : if detection of someone (at least 3 times during 30s) and mode Eco selected -> triggers the Mode comfort for 30 minutes. Stay in Mode Confort if continuous detedtions, or go back to Mode Eco after 30 minutes.

