# Domoticz-Heatpump-Thermostat
Thermostat for domoticz using ESP 8266 and EasyESP as hardware

![Domoticz example](https://raw.githubusercontent.com/sasa27/Domoticz-Heatpump-Thermostat/master/exThermostat.png)

### Features
* Several modes: Frost, Eco, Comfort, Forced (choose your temperature with thermostat) and Auto
* Mode Auto uses Calendar defined with Dummy Selector Room-auto-Cal
* Stop Heatpump if temperature over a given threshold
* Start Heatpump if temperature below a given threshold
* Uses PIR : if detection of someone (at least 3 times during 3min) and mode Eco selected -> triggers the Mode comfort for 30 minutes. Stay in Mode Confort if continuous detedtions, or go back to Mode Eco after 30 minutes;
* Turbo mode : If the expected temperature is not reached after one hour, the heatpump temperature is increased by 1
* Holliday mode, if the current day is a hollyday, the thermostat uses a seconf calendar Room-Auto-Cal-Hollydays 

### Prerequisites
```
ESP8266 with ÈSP Easy installed (https://www.letscontrolit.com/)
ESP Easy  can have the following devices used by the thermostat : PIR, DHT22 (temperature and humidity), IR (with HeatPumpIR plugin)
```
![Hardware](https://raw.githubusercontent.com/sasa27/Domoticz-Heatpump-Thermostat/master/hardware.png)

### Installing

first part: dummy devices and codes for calling the heatpump
Dummy devices in DOMOTICZ :
```
Selector "Room-Auto-Cal" for managing plannings, with levels: Off, Frostfree, Eco, Comfort
Selector "Room-Auto-Cal-Hollydays" with levels: Off, Frostfree, Eco, Comfort
Selector "ACModeRoom" for calling ESP Easy, with levels: Off, Auto, Heat, Cool, Dry, Fan, Turbo
Thermostat "ACTempRoom" for calling ESP Easy
```
Variable created in Domoticz
```
'HeatTemp' -- user variable name for saving the state of the heat pump 
```
Add the code ACRoom.lua in domoticz (Events, type Devices)
In this code, variable names can be changed as desired, as well as the IP address of the Heatpump

Voilà, your heatpump is digitalised and can be called everywhere !

second part: dummy devices and codes for calling the thermostat
Dummy devices in DOMOTICZ :
```
Selector "selector", for managing Thermostat Modes, with levels: Off, Frostfree, Eco, Comfort, Forced
Thermostat "thermostat", for managing wanted temperature
```

Variable created in Domoticz
```
'presencefirstRoom' --for starting to count the PIr occurences
'presencecountRoom' -- count the pir occurences during 3 minutes
'HeatTemp' -- user variable name for saving the state of the heat pump 
```
and a real temperature device

Add the code ThermostatRoom.lua in domoticz (Events, type Devices)
```
-- variables to edit ------
--------------------------------
local debugging = false--pour voir les logs dans la console log Dz ou false pour ne pas les voir
local fixedTemp = 'thermostat'  --domoticz button thermostat, used with force mode
local mode ='selector' --domoticz button mode choosen 
local automode='Room-Auto-Cal' -- selector button with planning allowing to manage the auto mode

-- holidays
local holidaybool=true
local automodeH='Room-Auto-Cal-Holidays' -- special Selector for planning management, for holidays (and school holidays), leave blanck if no required
local holivar='holiday' -- domoticz var affected to decimal 1-> true 0-> false no holiday today

--user present 
local presentbool=false --special mode if someone is inside and if eco ->change to confort
local presence = '' --Pir check if someone is inside if eco change to confort
local presencefirst='presencefirstRoom' --for starting to count the PIr occurences
local presencecount='presencecountRoom' -- count the pir occurences during 3 minutes
local prestime=30 --time during which user is present after detecttion in minutes

--heatpump
local HeatpumpMode='ACModeRoom' -- dummy selector for changing HT mode
local heatpumpT='ACTempRoom' -- dummy thermostat for setting/ storing its assigned temperature
local HeatPumpTidx='1900'

--temperatures w.r.t. modes
local fixedtemp = {
    Eco = 16.0;
    Frostfree= 12.0;
    Comfort=19;
    Auto = 0.0;
    Off=0.0;
}
local hysteresis = 0.5 -- theshold value
local triggerHeat=0.5 -- threshold value for starting/stopping heat pump

--sensors
local tsensor='TempHum int'; --for one sensor onlyæ
```

How to know whether a day is a holly day ?
with a script ! 
example in france: (this script is called every night at midnight)
```
local holidaysURL='http://domogeek.entropialux.com/holidayall/' -- web service URL for checking whether day = holiday 
local holidayZone ='A' -- french zone for holidays checking, A, B, or C

function checkholidays()
    if (holidaysURL=='') then 
        return false
        end
  json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()  -- For Linux
  --json = (loadfile "D:\\Domoticz\\scripts\\lua\\json.lua")()  -- For Windows
  local config=assert(io.popen('curl '..holidaysURL..holidayZone..'/now'))
  local hol = config:read('*all')
  config:close()
  local jsonH = json:decode(hol)
       if (jsonH.holiday=='False' and jsonH.schoolholiday=='False') then
       see_logs('No holiday today')
       return false
   else
       see_logs('holiday today :)')
       return true
      end
end

--after a commandarray():
  --check for holiday
    if (checkholidays()==true) then
        commandArray['Variable:holiday']='1';
    else
        commandArray['Variable:holiday']='0';
    end
```
