--command heatpump espeasy plugin 115
--var to change
local debugging = false
local adr = {'192.168.1.2','192.168.1.3'} --IP addresses of the ESPeasy modules
local model='toshiba'  -- model of Heatpump
local Tempmin=17 -- temp min accepted by model
local Tempmax=25 -- temp max accepted by model
local Calibre=0; -- calibration of the heatpump
--dummy button for command
local ACMode='ACModeRoom' -- dummy selector
local ACTemp='ACTempRoom' --dummy thermostat
local ACTempidx='1900' --dummy thermostat idx
local noheatpump=false -- true simulation, false sends commands
local HeatTemp='HeatTemp' -- user variable name for saving the state of the heat pump 


-- url format sent to esp
--http://192.168.1.7/control?cmd=heatpumpir,toshiba,0,0,0,19,0,0
--http://192.168.1.7/control?cmd=heatpumpir,toshiba,1,2,0,19,0,0
-- * The parameters are (in this order)
-- * * The type of the heatpump as a string, see the implementations of different models, like https://github.com/ToniA/arduino-heatpumpir/blob/master/MitsubishiHeatpumpIR.cpp
-- * * power state (see https://github.com/ToniA/arduino-heatpumpir/blob/master/HeatpumpIR.h for modes)
-- * * operating mode
-- * * fan speed
-- * * temperature
-- * * vertical air direction
-- * * horizontal air direction
--// Power state
--#define POWER_OFF   0
--#define POWER_ON    1
--
--// Operating modes
--#define MODE_AUTO   1
--#define MODE_HEAT   2
--#define MODE_COOL   3
--#define MODE_DRY    4
--#define MODE_FAN    5
--#define MODE_MAINT  6
--
--// Fan speeds. Note that some heatpumps have less than 5 fan speeds
--#define FAN_AUTO    0
--#define FAN_1       1
--#define FAN_2       2
--#define FAN_3       3
--#define FAN_4       4
--#define FAN_5       5
--
--// Vertical air directions. Note that these cannot be set on all heat pumps
--#define VDIR_AUTO   0
--#define VDIR_MANUAL 0
--#define VDIR_SWING  1
--#define VDIR_UP     2
--#define VDIR_MUP    3
--#define VDIR_MIDDLE 4
--#define VDIR_MDOWN  5
--#define VDIR_DOWN   6
--
--// Horizontal air directions. Note that these cannot be set on all heat pumps
--#define HDIR_AUTO   0
--#define HDIR_MANUAL 0
--#define HDIR_SWING  1
--#define HDIR_MIDDLE 2
--#define HDIR_LEFT   3
--#define HDIR_MLEFT  4
--#define HDIR_MRIGHT 5
--#define HDIR_RIGHT  6
--// Power state
--#define POWER_OFF   0
--#define POWER_ON    1
--
function see_logs (s)
    if (debugging ) then 
        print ("<font color='#031df3'>".. s .."</font>");
    end
    return
end	

commandArray = {}
--test user Variable
if(uservariables[HeatTemp] == nil) then
    noBlankDomoticz_Devicename = string.gsub(HeatTemp, " ", "+")
    commandArray['OpenURL'] = 'http://localhost:8080/json.htm?type=command&param=saveuservariable&vname='..noBlankDomoticz_Devicename..'&vtype=2&vvalue=1'
end
mode = otherdevices[ACMode]
for key, value in pairs(devicechanged) do
  if (key == ACMode or (key == ACTemp and mode ~='Off')) then
    t =  tonumber(string.sub(otherdevices_svalues[ACTemp],1,5))+Calibre
    if t<Tempmin then 
         see_logs('fixing temp min from'..t..' to '..Tempmin)
         --commandArray['SendNotification']= 'Error AC:#Change configuration fixing temp min from'..t..' to '..Tempmin;
        t=Tempmin
         --commandArray['UpdateDevice']=ACTempidx..'|0|'..t;
         --commandArray['OpenURL'] = 'http://127.0.0.1:8080/json.htm?type=command&param=udevice&idx='.. ACTempidx .. '&nvalue=0&svalue=' .. t
         
        end
    if t>Tempmax then 
        t=Tempmax
        --commandArray['UpdateDevice']=ACTempidx..'|0|'..t;
        see_logs('fixing temp max from'..t..' to '..Tempmin)
         commandArray['SendNotification']= 'Error AC:#Change configuration fixing temp max from'..t..' to '..Tempmin;
        --commandArray['OpenURL'] = 'http://127.0.0.1:8080/json.htm?type=command&param=udevice&idx='.. ACTempidx .. '&nvalue=0&svalue=' .. t
        end    
    powerModeCmd = 1 
    heatModeCmd = 2
    if mode == 'Off'   then 
        powerModeCmd = 0 
    elseif (mode == 'Auto')  then 
        heatModeCmd = 1
    elseif (mode == 'Heat' or mode == 'Turbo')  then 
        heatModeCmd = 2
    elseif (mode == 'Cool')  then 
        heatModeCmd = 3
    elseif (mode == 'Dry')   then 
        heatModeCmd = 4
    elseif (mode == 'Fan')   then 
        heatModeCmd = 5
    end
    for cle, valeur in ipairs(adr) do
        if ( key==ACMode or (key==ACTemp and t ~=uservariables[HeatTemp]) ) then
        modeCmd ='curl http://'..valeur..'/control?cmd=heatpumpir,'.. model..','.. powerModeCmd..','..heatModeCmd.. ',0,'..t..',0,0'
        commandArray['Variable:'..HeatTemp]=tostring(t)
        see_logs('ESP sending command:  '..modeCmd)
        if noheatpump==false then
            config=assert(io.popen(modeCmd))
            ret = config:read('*all')
            config:close();
        else ret='simu'
        end
        see_logs('call of heatpump: '..valeur..':'..ret..'.')
        if ret ~='Heatpump IR code transmitted' then 
            commandArray['SendNotification']= 'Error#: ESP Error ret='..ret
        end
        end
    end
  end
end
return commandArray

