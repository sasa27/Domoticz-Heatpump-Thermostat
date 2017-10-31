# Domoticz-Heatpump-Thermostat
Thermostat for domoticz using ESP 8266 and EasyESP as hardware

![Domoticz example](https://raw.githubusercontent.com/sasa27/Domoticz-Heatpump-Thermostat/master/exThermostat.png)

### Features
* Several modes: Frost, Eco, Comfort, Forced (choose your temperature with thermostat) and Auto
* Mode Auto uses Calendar defined with Dummy Selector Room-auto-Cal
* Stop Heatpump if temperature over a given threshold
* Start Heatpump if temperature below a given threshold
* Uses PIR : if detection of someone (at least 3 times during 3min) and mode Eco selected -> triggers the Mode comfort for 30 minutes. Stay in Mode Confort if continuous detedtions, or go back to Mode Eco after 30 minutes.

### Prerequisites
```
ESP8266 with ÈSP Easy installed (https://www.letscontrolit.com/)
ESP Easy  can have the following devices used by the thermostat : PIR, DHT22 (temperature and humidity), IR (with HeatPumpIR plugin)
```
### Installing
```
Dummy devices in DOMOTICZ :
Temperature,
Selector "selector", for managing Thermostat Modes,
Selector "Room-Auto-Cal" for managing plannings, 
Thermostat "thermostat", for managing wanted temperature
Selector "ACModeRoom" for calling ESP Easy
Thermostat "ACTempRoom" for calling ESP Easy
```
```
Variable created in Domoticz
'presencefirstRoom' --for starting to count the PIr occurences
'presencecountRoom' -- count the pir occurences during 3 minutes
'HeatTemp' -- user variable name for saving the state of the heat pump 
```

All these dummy devices and IPs can be modified with local variables in the begining of the script ThermostatRoom

```
Thermostat code given by two LUA Scripts (started in Device mode)
ACRoom -> manage ESP Easy with Third Selector ACModeRoom and Thermostat
ThermostatRoom -> code of the Thermostat
```


