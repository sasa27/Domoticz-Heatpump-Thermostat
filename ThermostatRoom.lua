--thermostat for heat pump / AC 
-- heat only 
-- variables to edit ------
--------------------------------
local debugging = false --pour voir les logs dans la console log Dz ou false pour ne pas les voir
local fixedTemp = 'thermostat'  --domoticz button thermostat, used with force mode
local mode ='selector' --domoticz button mode choosen 
local automode='Room-Auto-Cal' -- selector button with planning allowing to manage the auto mode

-- holidays
local holidaybool=true -- checks if today is a holyday
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
local tmode=2; -- 1 = 1 temperature sensor; 2= humidity/temperature combined sensor

local CurrentHPMode=otherdevices[HeatpumpMode];
local CurrentHPT = tonumber(string.sub(otherdevices_svalues[heatpumpT],1,5));

function see_logs (s)
    if (debugging ) then 
        s=automode .. ":".. s
        print ("<font color='#f3031d'>".. s .."</font>");
    end
    return
end	

function timedifference(s)
   local year = string.sub(s, 1, 4)
   local month = string.sub(s, 6, 7)
   local day = string.sub(s, 9, 10)
   local hour = string.sub(s, 12, 13)
   local minutes = string.sub(s, 15, 16)
   local seconds = string.sub(s, 18, 19)
   local t1 = os.time()
   local t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   local di = os.difftime (t1, t2)
   return di
end

--change heat pump state, state=on;off;minus,plus, t=temperature; 
function heatpump(state,t)
    local modes = {
        Off=0;
        Auto=10;
        Heat=20;
        Cool=30;
        Dry=40;
        Fan=50;
        Turbo=60;
        };
if CurrentHPMode ~=state then 
    commandArray[HeatpumpMode]='Set Level '..modes[state];
    CurrentHPMode=state
    see_logs('Thermostat: HeatPump changing state: '..state);
end

if (CurrentHPT  ~= t) then
    --commandArray['UpdateDevice']=HeatPumpTidx..'|0|'..t;
    commandArray['OpenURL'] = 'http://127.0.0.1:8080/json.htm?type=command&param=udevice&idx='.. HeatPumpTidx .. '&nvalue=0&svalue=' .. tostring(t)
    
    see_logs('Thermostat: HeatPump changing temp: '..t);
    CurrentHPT=t
end
    return
    end

commandArray = {}
--test user Variable
if(uservariables[presencefirst] == nil) then
    noBlankDomoticz_Devicename = string.gsub(presencefirst, " ", "+")
    commandArray['OpenURL'] = 'http://127.0.0.1:8080/json.htm?type=command&param=saveuservariable&vname='.. noBlankDomoticz_Devicename..'&vtype=2&vvalue=1';
    --json.htm?type=command&param=saveuservariable&vname=uservariablename&vtype=uservariabletype&vvalue=uservariablevalue
    see_logs('add variable '..presencefirst);
end
if(uservariables[presencecount] == nil) then
    noBlankDomoticz_Devicename = string.gsub(presencecount, " ", "+")
    commandArray['OpenURL'] = 'http://localhost:8080/json.htm?type=command&param=saveuservariable&vname='..noBlankDomoticz_Devicename..'&vtype=0&vvalue=0';
     see_logs('add variable '.. presencecount);
end
--test offline
if  (devicechanged[mode]=='Off')  and CurrentHPMode ~='Off' then
            see_logs("Thermostat: shutdown");
            heatpump('Off',CurrentHPT);
            return commandArray;
end
local Temp
see_logs('Current Ac mode: '..CurrentHPMode);
--check sensor 
difference = timedifference(otherdevices_lastupdate[tsensor])
      if (difference > 3600) then
          --sensor issue
          --commandArray['SendNotification']= 'Error:#Thermostat Sensor issue '.. tsensor;
          return commandArray;
      else
        if tmode==2 then
    Temp = tonumber(string.sub(otherdevices_svalues[tsensor],1,4));
else
    Temp = otherdevices_svalues[tsensor];
    end
end
see_logs('Thermostat: Current mode:'..otherdevices[mode]);
see_logs('Thermostat: Current temperature:'..Temp);
local expectedTemp;--get expected temp
local diff_change; --time delay from last change
if otherdevices[mode]=='Forced' then
        expectedTemp = tonumber(string.sub(otherdevices_svalues[fixedTemp],1,5));
    elseif otherdevices[mode]=='Auto' then
        --check for holidays
        if (holidaybool==true and uservariables[holivar]==1) then
            expectedTemp= fixedtemp[otherdevices[automodeH]];
            --diff_change=timedifference(otherdevices_lastupdate[automodeH]); 
            see_logs('Thermostat: in auto, current mode:'..otherdevices[automodeH]);
        else    
        expectedTemp= fixedtemp[otherdevices[automode]];
        --diff_change=timedifference(otherdevices_lastupdate[automode]);
        see_logs('Thermostat: in auto, current mode:'..otherdevices[automode]);
        end
        
        else
        expectedTemp= fixedtemp[otherdevices[mode]];
        --diff_change=timedifference(otherdevices_lastupdate[automode]);
    end
diff_change=timedifference(otherdevices_lastupdate[HeatpumpMode]);
see_logs('Time delay since last change: '..diff_change);
see_logs('Thermostat: expected temperature:'.. tostring(expectedTemp));
see_logs('Thermostat: HeatPump temperature:'.. tostring(CurrentHPT));
--Pir
if (devicechanged[presence]=='On') then
        difference = timedifference(uservariables_lastupdate[presencefirst]);
        difference2 = timedifference(uservariables_lastupdate[presencecount]);
        see_logs('pir '.. difference .. ' ' .. difference2);
      if (difference < 180 or (difference2 < prestime*60 and uservariables[presencecount]>2)  ) then
          commandArray['Variable:' .. presencecount] = tostring(tonumber(uservariables[presencecount])+1);
          see_logs("Thermostat Pir: " .. tostring(tonumber(uservariables[presencecount])+1));
          else
          commandArray['Variable:' .. presencecount] = "1";
          commandArray['Variable:' .. presencefirst] = "up";
          see_logs("Thermostat Pir: 1");
end
end
--presence
if (presentbool==true) then
difference = timedifference(uservariables_lastupdate[presencecount])
time = os.date("*t");
see_logs(time.hour)
      if (time.hour>=8 and time.hour<20 and difference < prestime*60 and uservariables[presencecount]>2 and expectedTemp==fixedtemp['Eco']) then
          --someone present and eco -> confort
          see_logs('Thermostat: mode eco but presence detected since '..(difference/60)..' minutes-> Comfort mode');
        expectedTemp=fixedtemp['Comfort'];
       -- commandArray['SendNotification']= 'Error:#Thermostat pir min'..(difference/60)..' '.. uservariables[presencecount];
    end
    end
--normal start HP 
if otherdevices[mode]~='Off' and CurrentHPMode=='Off' and (Temp <= expectedTemp - hysteresis) then
        see_logs("Thermostat: Heatpump start");
        heatpump('Heat',expectedTemp);
        return commandArray;
end
-- if real temp > expected + triggerHeat-> shutdown HP
if (Temp >= expectedTemp + triggerHeat) then
    if CurrentHPMode=='Heat' then
        see_logs("Thermostat:  temp difference important, Heatpump shutdown");
        heatpump('Off',CurrentHPT);
        return commandArray;
    end
end    
-- if real temp < expected and HP is shutdown-> start HP 
if (Temp <= expectedTemp - triggerHeat) then
    if CurrentHPMode=='Off' then
        see_logs("Thermostat: temp difference less important, Heatpump start");
        heatpump('Heat',expectedTemp);
        return commandArray;
    end
end  
--reduce temp heat pump
if CurrentHPMode == 'Heat' and (CurrentHPT > expectedTemp+hysteresis) then 
        see_logs("Thermostat: reduce temp Heat pump");
        heatpump('Heat',expectedTemp);
        return commandArray;
        end
if CurrentHPMode == 'Heat' and (CurrentHPT  < expectedTemp-hysteresis)  then 
    --increase temp heat pump
        see_logs("Thermostat: increase temp Heat pump to "..expectedTemp);
        heatpump('Heat',expectedTemp);
        return commandArray;
        end
--turbo mode
if (CurrentHPMode == 'Heat') and (diff_change > 3600) and (diff_change <= 5400) and (Temp  < expectedTemp-hysteresis) then 
    --temp not yet reached -> turbo mode ?
    see_logs("Thermostat: Turbo, increase temp Heat pump to "..expectedTemp+1);
    heatpump('Turbo',expectedTemp+1);
    return commandArray;
end
--turbo mode for 30 min -> stop
if (CurrentHPMode == 'Turbo') and  (diff_change > 1800) and (diff_change <= 3600) then 
    see_logs("Thermostat: Turbo, reduce temp Heat pump to "..expectedTemp);
    heatpump('Heat',expectedTemp);
    return commandArray;
end
return commandArray;
