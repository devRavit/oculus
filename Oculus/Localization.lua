-- Oculus Localization
-- Korean (koKR) and English (enUS)

local AddonName, Oculus = ...

-- Localization Table
local L = {}
Oculus.L = L

-- Available Languages
Oculus.Languages = {
    ["enUS"] = "English",
    ["koKR"] = "한국어",
}

-- Locale Strings Storage
local Locales = {}

-- English (Default)
Locales["enUS"] = {
    -- General
    ["Addon Description"] = "PvP addon that lets you see everything in combat",

    -- Settings Panel
    ["Profile"] = "Profile",
    ["Export"] = "Export",
    ["Import"] = "Import",
    ["Commands"] = "Commands",
    ["Close"] = "Close",
    ["Enable"] = "Enable",

    -- Module Names
    ["Unit Frames"] = "Unit Frames",
    ["Raid Frames"] = "Raid Frames",
    ["Arena Frames"] = "Arena Frames",

    -- Module Descriptions
    ["Unit Frames Desc"] = "Player/Target/Focus buff/debuff filter",
    ["Raid Frames Desc"] = "Party buff/debuff + cooldown tracking + enemy cast alert",
    ["Arena Frames Desc"] = "Arena frame sorting + buff/debuff filter",

    -- Export/Import Dialog
    ["Export Profile"] = "Export Profile",
    ["Import Profile"] = "Import Profile",
    ["Copy Instructions"] = "|cFFFFFF00Ctrl+C|r to copy, then |cFFFFFF00Ctrl+V|r to share",
    ["Paste Instructions"] = "Paste your profile string below (|cFFFFFF00Ctrl+V|r)",

    -- Messages
    ["Module Enabled"] = "enabled",
    ["Module Disabled"] = "disabled",
    ["Module Registered"] = "Module registered",
    ["Module Not Found"] = "Module not found",
    ["Module Already Registered"] = "Module already registered",
    ["Module Status"] = "Module Status",
    ["Import Success"] = "Profile imported successfully! /reload to apply.",
    ["Import Failed"] = "Import failed",
    ["Import Empty"] = "Empty string",
    ["Invalid Data"] = "Invalid data",
    ["Test Not Implemented"] = "Test mode not yet implemented",
    ["Unknown Command"] = "Unknown command",

    -- Commands Help
    ["Cmd Open Settings"] = "/oculus - Open settings",
    ["Cmd Enable Module"] = "/oculus enable <module> - Enable module",
    ["Cmd Disable Module"] = "/oculus disable <module> - Disable module",
    ["Cmd Status"] = "/oculus status - Show module status",
    ["Cmd Test"] = "/oculus test - Test mode (preview)",
    ["Cmd Version"] = "/oculus version - Show version",
    ["Cmd Export"] = "/oculus export - Export profile",
    ["Cmd Import"] = "/oculus import - Import profile",

    -- Settings Note
    ["Settings Note"] = "Module-specific settings will appear here when the module is loaded.",

    -- Language Confirm Dialog
    ["Language Confirm"] = "Change language and reload UI?",
    ["Yes"] = "Yes",
    ["No"] = "No",
}

-- Korean
Locales["koKR"] = {
    -- General
    ["Addon Description"] = "PvP 전투에서 모든 것을 볼 수 있게 해주는 애드온",

    -- Settings Panel
    ["Profile"] = "프로필",
    ["Export"] = "내보내기",
    ["Import"] = "가져오기",
    ["Commands"] = "명령어",
    ["Close"] = "닫기",
    ["Enable"] = "활성화",
    ["Language"] = "언어",

    -- Module Names
    ["Unit Frames"] = "유닛 프레임",
    ["Raid Frames"] = "레이드 프레임",
    ["Arena Frames"] = "투기장 프레임",

    -- Module Descriptions
    ["Unit Frames Desc"] = "플레이어/대상/주시대상 버프/디버프 필터",
    ["Raid Frames Desc"] = "파티 버프/디버프 + 쿨다운 트래킹 + 적 시전 알림",
    ["Arena Frames Desc"] = "투기장 프레임 정렬 + 버프/디버프 필터",

    -- Export/Import Dialog
    ["Export Profile"] = "프로필 내보내기",
    ["Import Profile"] = "프로필 가져오기",
    ["Copy Instructions"] = "|cFFFFFF00Ctrl+C|r로 복사 후 |cFFFFFF00Ctrl+V|r로 공유",
    ["Paste Instructions"] = "프로필 문자열을 아래에 붙여넣기 (|cFFFFFF00Ctrl+V|r)",

    -- Messages
    ["Module Enabled"] = "활성화됨",
    ["Module Disabled"] = "비활성화됨",
    ["Module Registered"] = "모듈 등록됨",
    ["Module Not Found"] = "모듈을 찾을 수 없음",
    ["Module Already Registered"] = "이미 등록된 모듈",
    ["Module Status"] = "모듈 상태",
    ["Import Success"] = "프로필을 성공적으로 가져왔습니다! /reload로 적용하세요.",
    ["Import Failed"] = "가져오기 실패",
    ["Import Empty"] = "빈 문자열",
    ["Invalid Data"] = "잘못된 데이터",
    ["Test Not Implemented"] = "테스트 모드가 아직 구현되지 않았습니다",
    ["Unknown Command"] = "알 수 없는 명령어",
    ["Language Changed"] = "언어가 변경되었습니다. /reload로 적용하세요.",

    -- Commands Help
    ["Cmd Open Settings"] = "/oculus - 설정 열기",
    ["Cmd Enable Module"] = "/oculus enable <모듈> - 모듈 활성화",
    ["Cmd Disable Module"] = "/oculus disable <모듈> - 모듈 비활성화",
    ["Cmd Status"] = "/oculus status - 모듈 상태 보기",
    ["Cmd Test"] = "/oculus test - 테스트 모드 (미리보기)",
    ["Cmd Version"] = "/oculus version - 버전 보기",
    ["Cmd Export"] = "/oculus export - 프로필 내보내기",
    ["Cmd Import"] = "/oculus import - 프로필 가져오기",

    -- Settings Note
    ["Settings Note"] = "모듈이 로드되면 모듈별 설정이 여기에 표시됩니다.",

    -- Language Confirm Dialog
    ["Language Confirm"] = "언어를 변경하고 UI를 다시 불러올까요?",
    ["Yes"] = "예",
    ["No"] = "아니오",
}

-- Add missing keys to English
Locales["enUS"]["Language"] = "Language"
Locales["enUS"]["Language Changed"] = "Language changed. /reload to apply."

-- Get Current Language (checks saved setting first, then client locale)
function Oculus:GetLanguage()
    -- Check saved setting
    if OculusDB and OculusDB.Language and Locales[OculusDB.Language] then
        return OculusDB.Language
    end
    -- Fall back to client locale
    local ClientLocale = GetLocale()
    return Locales[ClientLocale] and ClientLocale or "enUS"
end

-- Set Language
function Oculus:SetLanguage(Lang)
    if not Locales[Lang] then
        return false
    end
    if not OculusDB then
        OculusDB = {}
    end
    OculusDB.Language = Lang
    return true
end

-- Metatable for L - dynamically gets strings based on current language
setmetatable(L, {
    __index = function(_, Key)
        local Lang = Oculus:GetLanguage()
        local Strings = Locales[Lang] or Locales["enUS"]
        return Strings[Key] or Locales["enUS"][Key] or Key
    end,
})
