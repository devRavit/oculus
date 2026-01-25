--[[
    Oculus Utils
    Utility functions including Base64 encoding/decoding and serialization
]]

local addonName, Oculus = ...


-- Lua API Localization
local pairs = pairs
local type = type
local tostring = tostring
local table = table
local string = string
local math = math
local loadstring = loadstring
local pcall = pcall


-- Constants
local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


-- Utils Module
Oculus.Utils = {}
local Utils = Oculus.Utils


-- Base64 Encode
function Utils.Base64Encode(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then
            return ""
        end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
        end
        return BASE64_CHARS:sub(c + 1, c + 1)
    end) .. ({"", "==", "="})[#data % 3 + 1])
end

-- Base64 Decode
function Utils.Base64Decode(data)
    data = data:gsub("[^" .. BASE64_CHARS .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then
            return ""
        end
        local r, f = "", (BASE64_CHARS:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then
            return ""
        end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

-- Serialize value (local helper)
local function serializeValue(val, indent)
    indent = indent or ""
    local valType = type(val)

    if valType == "table" then
        local parts = {}
        local isArray = true
        local maxIndex = 0

        -- Check if it's an array
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            if k > maxIndex then
                maxIndex = k
            end
        end

        if isArray and maxIndex > 0 then
            for i = 1, maxIndex do
                table.insert(parts, serializeValue(val[i], indent .. " "))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            for k, v in pairs(val) do
                local key
                if type(k) == "string" then
                    if k:match("^[%a_][%w_]*$") then
                        key = k
                    else
                        key = "[\"" .. k:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\"]"
                    end
                else
                    key = "[" .. tostring(k) .. "]"
                end
                table.insert(parts, key .. "=" .. serializeValue(v, indent .. " "))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end

    elseif valType == "string" then
        return "\"" .. val:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r") .. "\""

    elseif valType == "number" or valType == "boolean" then
        return tostring(val)

    else
        return "nil"
    end
end

-- Serialize table to string
function Utils.Serialize(tbl)
    return serializeValue(tbl)
end

-- Deserialize string to table
function Utils.Deserialize(str)
    if not str or str == "" then
        return nil, "Empty string"
    end

    local func, err = loadstring("return " .. str)
    if not func then
        return nil, err
    end

    local success, result = pcall(func)
    if not success then
        return nil, result
    end

    if type(result) ~= "table" then
        return nil, "Result is not a table"
    end

    return result
end

-- Export profile to encoded string
function Utils.ExportProfile(data)
    local serialized = Utils.Serialize(data)
    local encoded = Utils.Base64Encode(serialized)
    return encoded
end

-- Import profile from encoded string
function Utils.ImportProfile(str)
    local decoded = Utils.Base64Decode(str)
    if not decoded or decoded == "" then
        return nil, "Failed to decode"
    end

    local data, err = Utils.Deserialize(decoded)
    if not data then
        return nil, err
    end

    return data
end
