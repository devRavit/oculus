-- Oculus Core - Logger
-- Centralized logging system for all Oculus modules

local addonName, Oculus = ...


-- Logger Module
local Logger = {}
Oculus.Logger = Logger


-- Constants
local MAX_LOGS = 500


-- Get timestamp
local function getTimestamp()
    return date and date("%Y-%m-%d %H:%M:%S") or "NODATE"
end


-- Write to SavedVariables (persistent across sessions)
local function writeToSavedVariables(message)
    if not _G.OculusLogs then
        _G.OculusLogs = {}
    end

    -- Use pcall to safely insert - handles secret values
    local success = pcall(function()
        table.insert(_G.OculusLogs, message)
    end)

    if not success then
        -- If insert failed (likely due to secret value), insert a placeholder
        pcall(function()
            table.insert(_G.OculusLogs, "[LOG FAILED: Secret Value in message]")
        end)
    end

    -- Keep only last MAX_LOGS
    if #_G.OculusLogs > MAX_LOGS then
        table.remove(_G.OculusLogs, 1)
    end
end


-- Log function
function Logger:Log(module, submodule, message)
    local timestamp = getTimestamp()
    local sub = submodule or "Core"
    local msg = message or "NOMSG"

    local formattedLog = "[" .. timestamp .. "] [" .. module .. ":" .. sub .. "] " .. msg

    -- Save to SavedVariables only
    writeToSavedVariables(formattedLog)
end


-- Get all logs from SavedVariables
function Logger:GetLogs()
    return _G.OculusLogs or {}
end


-- Clear all logs
function Logger:Clear()
    _G.OculusLogs = {}
end
