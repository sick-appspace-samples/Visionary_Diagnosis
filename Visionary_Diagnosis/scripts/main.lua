--[[----------------------------------------------------------------------------

  Application Name: Visionary_Diagnosis
    
  Summary:
  Shows some device information and allows to download a diagnosis dump
  
  Description:
  Shows some device information and provides a button on the UI to download a
  diagnosis dump
  
  How to run:
  Start by running the app (F5) or debugging (F7+F10).
    
------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- Variables, constants, serves etc. should be declared here.
local json = require("json")

local tmr = Timer.create()
Messages = {}

ErrorMap = {
  DEBUG = "Debug,",
  INFO = "Info",
  WARNING = "Warning",
  ERROR = "Error",
  FATAL_ERROR = "Fatal"
}

StateMap = {
  INACTIVE = "Inactive",
  ACTIVE = "Active",
  CLEAR = "Clear",
  PERMANENT = "Permanent",
  UNKNOWN = "Unknown"
}
--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------
---Get temperature of Illunination
---@return float temperature in Celcius
local function getIlluminationTemperature()
  local temperature = Monitor.Temperature.create("VCSEL")
  return temperature:get()
end
Script.serveFunction("Visionary_Diagnosis.getIlluminationTemperature", getIlluminationTemperature)

---Get temperature of CPU
---@return float temperature in Celcius
local function getCPUTemperature()
  local temperature = Monitor.Temperature.create('MAIN_CPU')
  -- Format COU Temperature to xx.xx°C
  local cpuTempRounded = math.floor(temperature:get() * 100) / 100 
  return cpuTempRounded
end
Script.serveFunction("Visionary_Diagnosis.getCPUTemperature", getCPUTemperature)

local function updateMessages()
  local logMessages = SystemLog.getSystemLog()
  local newMessages = {}
  for i = 1, #logMessages do
    local logMessage = logMessages[i]
    local errorId = SystemLog.Entry.getErrorId(logMessage)

    local numberOccurance = SystemLog.Entry.getNumberOfOccurences(logMessage)
    local firstTime = SystemLog.Entry.getFirstOccurence(logMessage)
    local lastTime = SystemLog.Entry.getLastOccurence(logMessage)
    local extInfo = SystemLog.Entry.getExtendedErrorMessage(logMessage)
    local message = SystemLog.Entry.getErrorMessage(logMessage)
    local state = SystemLog.Entry.getErrorState(logMessage)
    local level = SystemLog.Entry.getErrorLevel(logMessage)
    if errorId ~= 0 then
        table.insert(newMessages, i, {message=message, extInfo = extInfo, 
          timestamp = lastTime, firstOccurence=firstTime, 
          errorId = string.format("0x%x", errorId), 
          numberOccurred = numberOccurance, level=ErrorMap[level], state=StateMap[state] })
    end
  end
  Messages = newMessages
  local jsonstring = json.encode(Messages)
  -- Notify binding with new data
  Script.notifyEvent("OnNewMessages", jsonstring)
end

local function handleOnExpired()
  updateMessages()
end
Timer.register(tmr, "OnExpired", handleOnExpired)

Script.serveEvent("Visionary_Diagnosis.OnNewMessages", "OnNewMessages")

-- Function is bound to UI element and returns a json string with 
-- all table entries
---@return string json string which can be parsed by DynamicTable UI element
local function getMessages()
  -- Converting table to json string
  local jsonstring = json.encode(Messages)
  return jsonstring
end
Script.serveFunction("Visionary_Diagnosis.getMessages", getMessages)

local function main()
  updateMessages()
  tmr:setPeriodic(true)
  tmr:setExpirationTime(15000)
  tmr:start()
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope------------------------------------------------
