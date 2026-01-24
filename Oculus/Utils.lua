-- Oculus Utils
-- Utility functions including Base64 encoding/decoding and serialization

local AddonName, Oculus = ...

Oculus.Utils = {}
local Utils = Oculus.Utils

-- Base64 character set
local Base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Base64 Encode
function Utils.Base64Encode(Data)
    return ((Data:gsub(".", function(X)
        local R, B = "", X:byte()
        for I = 8, 1, -1 do
            R = R .. (B % 2 ^ I - B % 2 ^ (I - 1) > 0 and "1" or "0")
        end
        return R
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(X)
        if #X < 6 then
            return ""
        end
        local C = 0
        for I = 1, 6 do
            C = C + (X:sub(I, I) == "1" and 2 ^ (6 - I) or 0)
        end
        return Base64Chars:sub(C + 1, C + 1)
    end) .. ({"", "==", "="})[#Data % 3 + 1])
end

-- Base64 Decode
function Utils.Base64Decode(Data)
    Data = Data:gsub("[^" .. Base64Chars .. "=]", "")
    return (Data:gsub(".", function(X)
        if X == "=" then
            return ""
        end
        local R, F = "", (Base64Chars:find(X) - 1)
        for I = 6, 1, -1 do
            R = R .. (F % 2 ^ I - F % 2 ^ (I - 1) > 0 and "1" or "0")
        end
        return R
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(X)
        if #X ~= 8 then
            return ""
        end
        local C = 0
        for I = 1, 8 do
            C = C + (X:sub(I, I) == "1" and 2 ^ (8 - I) or 0)
        end
        return string.char(C)
    end))
end

-- Serialize table to string
function Utils.Serialize(Tbl)
    local function SerializeValue(Val, Indent)
        Indent = Indent or ""
        local ValType = type(Val)

        if ValType == "table" then
            local Parts = {}
            local IsArray = true
            local MaxIndex = 0

            -- Check if it's an array
            for K, _ in pairs(Val) do
                if type(K) ~= "number" or K < 1 or math.floor(K) ~= K then
                    IsArray = false
                    break
                end
                if K > MaxIndex then
                    MaxIndex = K
                end
            end

            if IsArray and MaxIndex > 0 then
                for I = 1, MaxIndex do
                    table.insert(Parts, SerializeValue(Val[I], Indent .. " "))
                end
                return "{" .. table.concat(Parts, ",") .. "}"
            else
                for K, V in pairs(Val) do
                    local Key
                    if type(K) == "string" then
                        if K:match("^[%a_][%w_]*$") then
                            Key = K
                        else
                            Key = "[\"" .. K:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\"]"
                        end
                    else
                        Key = "[" .. tostring(K) .. "]"
                    end
                    table.insert(Parts, Key .. "=" .. SerializeValue(V, Indent .. " "))
                end
                return "{" .. table.concat(Parts, ",") .. "}"
            end

        elseif ValType == "string" then
            return "\"" .. Val:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r") .. "\""

        elseif ValType == "number" or ValType == "boolean" then
            return tostring(Val)

        elseif ValType == "nil" then
            return "nil"

        else
            return "nil"
        end
    end

    return SerializeValue(Tbl)
end

-- Deserialize string to table
function Utils.Deserialize(Str)
    if not Str or Str == "" then
        return nil, "Empty string"
    end

    local Func, Err = loadstring("return " .. Str)
    if not Func then
        return nil, Err
    end

    local Success, Result = pcall(Func)
    if not Success then
        return nil, Result
    end

    if type(Result) ~= "table" then
        return nil, "Result is not a table"
    end

    return Result
end

-- Export profile to encoded string
function Utils.ExportProfile(Data)
    local Serialized = Utils.Serialize(Data)
    local Encoded = Utils.Base64Encode(Serialized)
    return Encoded
end

-- Import profile from encoded string
function Utils.ImportProfile(Str)
    local Decoded = Utils.Base64Decode(Str)
    if not Decoded or Decoded == "" then
        return nil, "Failed to decode"
    end

    local Data, Err = Utils.Deserialize(Decoded)
    if not Data then
        return nil, Err
    end

    return Data
end
