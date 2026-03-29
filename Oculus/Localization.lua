-- Oculus Localization
-- Korean (koKR) and English (enUS)

local addonName, Oculus = ...


-- Lua API Localization
local pairs = pairs
local setmetatable = setmetatable

-- WoW API Localization
local GetLocale = GetLocale


-- Localization Table
local L = {}
Oculus.L = L

-- Available Languages
Oculus.Languages = {
    ["enUS"] = "English",
    ["koKR"] = "한국어",
}


-- Locale Strings Storage
local LOCALES = {}

-- English (Default)
LOCALES["enUS"] = {
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
    ["General Module"] = "General",

    -- Module Descriptions
    ["Unit Frames Desc"] = "Player/Target/Focus buff/debuff filter",
    ["Raid Frames Desc"] = "Party buff/debuff + cooldown tracking + enemy cast alert",
    ["Arena Frames Desc"] = "Arena frame sorting + buff/debuff filter",
    ["General Module Desc"] = "Reposition Blizzard frames (Totem Bar, Druid Bar)",

    -- General
    ["General Settings"] = "General Settings",
    ["Class Bar Settings"] = "Class Bar Settings",

    -- General Frame Mover
    ["Class Bar"] = "Class Bar",
    ["Frame Mover"] = "Frame Mover",
    ["Frame Mover Desc"] = "Drag frames to reposition them. Click Unlock to show drag handles.",
    ["Frame Lock"] = "Frame Lock",
    ["Frame Anchor"] = "Frame Anchor",
    ["Frame Position"] = "Frame Position",
    ["Frame Scale"] = "Frame Scale",
    ["Reset Positions"] = "Reset Positions",
    ["Unlock Frames"] = "Unlock Frames",
    ["Lock Frames"] = "Lock Frames",
    ["Reset Position"] = "Reset",
    ["Totem Bar"] = "Totem Bar",
    ["Druid Bar"] = "Druid Bar",
    ["GEN Reset Confirm"] = "Reset General settings to defaults?",

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

    -- RaidFrames Config
    ["Aura Display"] = "Aura Display",
    ["Aura Display Desc"] = "Configure buff and debuff icon display on raid frames.",
    ["Frame Settings"] = "Frame Settings",
    ["Hide Role Icon"] = "Hide Role Icon",
    ["Hide Name"] = "Hide Name",
    ["Hide Aggro Overlay"] = "Hide Aggro Overlay",
    ["Hide Party Title"] = "Hide Party Title",
    ["Range Settings"] = "Range Settings",
    ["Range Fade"] = "Range Fade",
    ["Range Fade Min Opacity (%)"] = "Min Opacity (%)",
    ["Buff Settings"] = "Buff Settings",
    ["Debuff Settings"] = "Debuff Settings",
    ["Timer Settings"] = "Timer Settings",
    ["Buff Icon Size"] = "Buff Icon Size",
    ["Debuff Icon Size"] = "Debuff Icon Size",
    ["Hide Dispel Overlay"] = "Hide Dispel Overlay",
    ["Hide Dispel Border"] = "Hide Dispel Border",
    ["Dispel Border Size"] = "Dispel Border Size",
    ["Show Duration Timer"] = "Show Duration Timer",
    ["Expiring Border Size"] = "Expiring Border Size",
    ["Timer Font Size"] = "Timer Font Size",
    ["Expiring Warning (%)"] = "Expiring Warning (%)",
    ["Actions"] = "Actions",
    ["Preview Mode"] = "Preview Mode",
    ["Reset to Defaults"] = "Reset to Defaults",
    ["Preview Not Available"] = "Preview not available yet",
    ["Settings Reset"] = "RaidFrames settings reset to defaults",
    ["Reset Confirm"] = "Reset RaidFrames settings to defaults?",
    ["Reset"] = "Reset",
    ["Cancel"] = "Cancel",

    -- RaidFrames Tooltips
    ["Tooltip Buff Size"] = "Size of buff icons displayed on raid frames.",
    ["Tooltip Debuff Size"] = "Size of debuff icons displayed on raid frames.",
    ["Tooltip Hide Dispel Overlay"] = "Hide the dispel overlay on party/raid frames when you can dispel a debuff.",
    ["Tooltip Hide Dispel Border"] = "Hide the colored border that indicates debuff type (Magic, Disease, Poison, Curse). When unchecked, borders will be enlarged for better visibility.",
    ["Tooltip Show Timer"] = "Display remaining time on aura icons.",
    ["Tooltip Expiring Warning"] = "When remaining duration falls below this percentage, show a red glow warning.",

    -- Tracked Spells
    ["Tracked Spells"] = "Tracked Spells",
    ["Tracked Spells Desc"] = "Spells that will show a flashing border when duration falls below threshold.",
    ["Add Spell ID"] = "Add Spell ID",
    ["Enter Spell ID"] = "Enter Spell ID...",
    ["Add"] = "Add",
    ["Remove"] = "Remove",
    ["No Tracked Spells"] = "No spells tracked. Add a spell ID above.",

    -- RaidFrames Tab/Category Names
    ["Buff Icon Settings"] = "Buff Icon Settings",

    -- RaidFrames Layout Settings
    ["Max Buffs"] = "Max Buffs",
    ["Max Debuffs"] = "Max Debuffs",
    ["Buffs Per Row"] = "Buffs Per Row",
    ["Debuffs Per Row"] = "Debuffs Per Row",
    ["Buff Anchor"] = "Buff Position",
    ["Debuff Anchor"] = "Debuff Position",
    ["Buff Spacing"] = "Buff Spacing",
    ["Debuff Spacing"] = "Debuff Spacing",
    ["Use Custom Position"] = "Use Custom Position",
    ["Tooltip Custom Position"] = "Enable custom positioning to manually control icon placement. When disabled, Blizzard's default layout is used.",

    -- Anchor Points
    ["TOPLEFT"] = "Top Left",
    ["TOP"] = "Top",
    ["TOPRIGHT"] = "Top Right",
    ["LEFT"] = "Left",
    ["CENTER"] = "Center",
    ["RIGHT"] = "Right",
    ["BOTTOMLEFT"] = "Bottom Left",
    ["BOTTOM"] = "Bottom",
    ["BOTTOMRIGHT"] = "Bottom Right",
    ["PORTRAIT"] = "Portrait (Cover)",

    -- UnitFrames LossOfControl Config
    ["CC Alert"] = "CC Alert",
    ["CC Alert Settings"] = "CC Alert Settings",
    ["CC Alert Position"] = "CC Alert Position",
    ["Hide Background"] = "Hide Background",
    ["Hide Red Lines"] = "Hide Red Lines",
    ["CC Alert Scale (%)"] = "Scale (%)",
    ["Offset X"] = "Offset X",
    ["Offset Y"] = "Offset Y",
    ["Preview CC Alert"] = "Preview CC Alert",
    ["Stop Preview"] = "Stop Preview",
    ["UF Reset Confirm"] = "Reset UnitFrames settings to defaults?",
    ["UF Settings Reset"] = "UnitFrames settings reset to defaults",

    -- UnitFrames Config
    ["UnitFrames"] = "UnitFrames",
    ["Icon Settings"] = "Icon Settings",
    ["Icon Size"] = "Icon Size",
    ["Position"] = "Position",
    ["Show Timer"] = "Show Timer",
    ["General"] = "General",
    ["Categories"] = "Categories",
    ["Custom Spells"] = "Custom Spells",
    ["Aura Categories"] = "Aura Categories",
    ["Crowd Control"] = "Crowd Control",
    ["Immunity"] = "Immunity",
    ["Defensive Buffs"] = "Defensive Buffs",
    ["Offensive Buffs"] = "Offensive Buffs",
    ["CC"] = "CC",
    ["Defensive"] = "Defensive",
    ["Offensive"] = "Offensive",
    ["CC Desc"] = "Stuns, fears, polymorphs, roots, and other crowd control effects",
    ["Immunity Desc"] = "Immunities and major damage reduction cooldowns",
    ["Defensive Desc"] = "Defensive cooldowns and protective buffs",
    ["Offensive Desc"] = "Offensive cooldowns and damage buffs",
    ["Add Custom Spell"] = "Add Custom Spell",
    ["Spell ID"] = "Spell ID",
    ["Category"] = "Category",
    ["Priority"] = "Priority",
    ["Invalid Spell ID"] = "Invalid Spell ID",
    ["Spell Not Found"] = "Spell not found",
    ["Added Spell"] = "Added spell:",
    ["Removed Spell"] = "Removed spell:",
    ["No Custom Spells"] = "No custom spells added. Add a spell above.",

    -- ArenaFrames Config
    ["Arena Scale"] = "Scale",
    ["Arena Scale (%)"] = "Scale (%)",
    ["Arena Spacing"] = "Spacing",
    ["Frame Spacing"] = "Frame Spacing",
    ["AF Reset Confirm"] = "Reset Arena Frames settings to defaults?",
}

-- Korean
LOCALES["koKR"] = {
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
    ["Arena Frames"] = "아레나 프레임",
    ["General Module"] = "일반",

    -- Module Descriptions
    ["Unit Frames Desc"] = "플레이어/대상/주시대상 버프/디버프 필터",
    ["Raid Frames Desc"] = "파티 버프/디버프 + 쿨다운 트래킹 + 적 시전 알림",
    ["Arena Frames Desc"] = "아레나 프레임 정렬 + 버프/디버프 필터",
    ["General Module Desc"] = "블리자드 프레임 위치 조정 (토템바, 드루이드 바)",

    -- General
    ["General Settings"] = "일반 설정",
    ["Class Bar Settings"] = "클래스바 설정",

    -- General Frame Mover
    ["Class Bar"] = "클래스 바",
    ["Frame Mover"] = "프레임 이동",
    ["Frame Mover Desc"] = "잠금 해제 후 드래그로 프레임 위치를 조정하세요.",
    ["Frame Lock"] = "잠금 설정",
    ["Frame Anchor"] = "확장 방향",
    ["Frame Position"] = "위치 설정",
    ["Frame Scale"] = "크기 설정",
    ["Reset Positions"] = "위치 초기화",
    ["Unlock Frames"] = "잠금 해제",
    ["Lock Frames"] = "잠금",
    ["Reset Position"] = "초기화",
    ["Totem Bar"] = "토템바",
    ["Druid Bar"] = "드루이드 바",
    ["GEN Reset Confirm"] = "General 설정을 기본값으로 초기화할까요?",

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

    -- RaidFrames Config
    ["Aura Display"] = "오라 표시",
    ["Aura Display Desc"] = "레이드 프레임에 표시되는 버프/디버프 아이콘을 설정합니다.",
    ["Frame Settings"] = "프레임 설정",
    ["Hide Role Icon"] = "역할군 아이콘 숨김",
    ["Hide Name"] = "이름 숨김",
    ["Hide Aggro Overlay"] = "어그로 오버레이 숨김",
    ["Hide Party Title"] = "파티 제목 숨김",
    ["Range Settings"] = "사거리 설정",
    ["Range Fade"] = "사거리 투명도",
    ["Range Fade Min Opacity (%)"] = "최소 불투명도 (%)",
    ["Buff Settings"] = "버프 설정",
    ["Debuff Settings"] = "디버프 설정",
    ["Timer Settings"] = "타이머 설정",
    ["Buff Icon Size"] = "버프 아이콘 크기",
    ["Debuff Icon Size"] = "디버프 아이콘 크기",
    ["Hide Dispel Overlay"] = "해제 오버레이 숨김",
    ["Hide Dispel Border"] = "해제 테두리 숨김",
    ["Dispel Border Size"] = "해제 테두리 크기",
    ["Show Duration Timer"] = "남은 시간 표시",
    ["Expiring Border Size"] = "만료 경고 테두리 크기",
    ["Timer Font Size"] = "타이머 폰트 크기",
    ["Expiring Warning (%)"] = "만료 경고 (%)",
    ["Actions"] = "동작",
    ["Preview Mode"] = "미리보기 모드",
    ["Reset to Defaults"] = "기본값으로 초기화",
    ["Preview Not Available"] = "미리보기 기능이 아직 준비되지 않았습니다",
    ["Settings Reset"] = "레이드 프레임 설정이 기본값으로 초기화되었습니다",
    ["Reset Confirm"] = "레이드 프레임 설정을 기본값으로 초기화할까요?",
    ["Reset"] = "초기화",
    ["Cancel"] = "취소",

    -- RaidFrames Tooltips
    ["Tooltip Buff Size"] = "레이드 프레임에 표시되는 버프 아이콘의 크기입니다.",
    ["Tooltip Debuff Size"] = "레이드 프레임에 표시되는 디버프 아이콘의 크기입니다.",
    ["Tooltip Hide Dispel Overlay"] = "해제 가능한 디버프가 있을 때 파티/레이드 프레임에 표시되는 오버레이를 숨깁니다.",
    ["Tooltip Hide Dispel Border"] = "디버프 종류를 나타내는 색상 테두리를 숨깁니다 (마법=파랑, 질병=갈색, 독=초록, 저주=보라). 체크 해제 시 테두리가 크고 선명하게 표시됩니다.",
    ["Tooltip Show Timer"] = "오라 아이콘에 남은 시간을 표시합니다.",
    ["Tooltip Expiring Warning"] = "남은 시간이 이 비율 미만일 때 빨간 테두리 경고를 표시합니다.",

    -- Tracked Spells
    ["Tracked Spells"] = "추적할 주문",
    ["Tracked Spells Desc"] = "지속시간이 임계값 미만으로 떨어지면 깜빡이는 테두리를 표시할 주문입니다.",
    ["Add Spell ID"] = "주문 ID 추가",
    ["Enter Spell ID"] = "주문 ID 입력...",
    ["Add"] = "추가",
    ["Remove"] = "제거",
    ["No Tracked Spells"] = "추적 중인 주문이 없습니다. 위에서 주문 ID를 추가하세요.",

    -- RaidFrames Tab/Category Names
    ["Buff Icon Settings"] = "버프 아이콘 설정",

    -- RaidFrames Layout Settings
    ["Max Buffs"] = "버프 총 개수",
    ["Max Debuffs"] = "디버프 총 개수",
    ["Buffs Per Row"] = "행당 버프 개수",
    ["Debuffs Per Row"] = "행당 디버프 개수",
    ["Buff Anchor"] = "버프 위치",
    ["Debuff Anchor"] = "디버프 위치",
    ["Buff Spacing"] = "버프 간격",
    ["Debuff Spacing"] = "디버프 간격",
    ["Use Custom Position"] = "커스텀 위치 사용",
    ["Tooltip Custom Position"] = "커스텀 위치 설정을 활성화하면 아이콘 위치를 수동으로 제어할 수 있습니다. 비활성화 시 블리자드 기본 레이아웃이 사용됩니다.",

    -- Anchor Points
    ["TOPLEFT"] = "좌측 상단",
    ["TOP"] = "상단",
    ["TOPRIGHT"] = "우측 상단",
    ["LEFT"] = "좌측",
    ["CENTER"] = "중앙",
    ["RIGHT"] = "우측",
    ["BOTTOMLEFT"] = "좌측 하단",
    ["BOTTOM"] = "하단",
    ["BOTTOMRIGHT"] = "우측 하단",
    ["PORTRAIT"] = "초상화 (덮어쓰기)",

    -- UnitFrames LossOfControl Config
    ["CC Alert"] = "군중제어불가 알림",
    ["CC Alert Settings"] = "군중제어불가 알림 설정",
    ["CC Alert Position"] = "군중제어불가 알림 위치",
    ["Hide Background"] = "배경 숨김",
    ["Hide Red Lines"] = "빨간 선 숨김",
    ["CC Alert Scale (%)"] = "크기 (%)",
    ["Offset X"] = "X 오프셋",
    ["Offset Y"] = "Y 오프셋",
    ["Preview CC Alert"] = "군중제어불가 알림 미리보기",
    ["Stop Preview"] = "미리보기 중지",
    ["UF Reset Confirm"] = "유닛 프레임 설정을 기본값으로 초기화할까요?",
    ["UF Settings Reset"] = "유닛 프레임 설정이 기본값으로 초기화되었습니다",

    -- UnitFrames Config
    ["UnitFrames"] = "유닛 프레임",
    ["Icon Settings"] = "아이콘 설정",
    ["Icon Size"] = "아이콘 크기",
    ["Position"] = "위치",
    ["Show Timer"] = "타이머 표시",
    ["General"] = "일반",
    ["Categories"] = "카테고리",
    ["Custom Spells"] = "커스텀 주문",
    ["Aura Categories"] = "오라 카테고리",
    ["Crowd Control"] = "군중 제어",
    ["Immunity"] = "면역",
    ["Defensive Buffs"] = "방어 버프",
    ["Offensive Buffs"] = "공격 버프",
    ["CC"] = "CC",
    ["Defensive"] = "방어",
    ["Offensive"] = "공격",
    ["CC Desc"] = "기절, 공포, 변이, 속박 등 군중 제어 효과",
    ["Immunity Desc"] = "무적 및 주요 피해 감소 쿨다운",
    ["Defensive Desc"] = "방어 쿨다운 및 보호 버프",
    ["Offensive Desc"] = "공격 쿨다운 및 공격력 버프",
    ["Add Custom Spell"] = "커스텀 주문 추가",
    ["Spell ID"] = "주문 ID",
    ["Category"] = "카테고리",
    ["Priority"] = "우선순위",
    ["Invalid Spell ID"] = "잘못된 주문 ID",
    ["Spell Not Found"] = "주문을 찾을 수 없음",
    ["Added Spell"] = "주문 추가됨:",
    ["Removed Spell"] = "주문 제거됨:",
    ["No Custom Spells"] = "추가된 커스텀 주문이 없습니다. 위에서 주문을 추가하세요.",

    -- ArenaFrames Config
    ["Arena Scale"] = "크기",
    ["Arena Scale (%)"] = "크기 (%)",
    ["Arena Spacing"] = "간격",
    ["Frame Spacing"] = "프레임 간격",
    ["AF Reset Confirm"] = "아레나 프레임 설정을 기본값으로 초기화할까요?",
}

-- Add missing keys to English
LOCALES["enUS"]["Language"] = "Language"
LOCALES["enUS"]["Language Changed"] = "Language changed. /reload to apply."

-- Get Current Language (checks saved setting first, then client locale)
function Oculus:GetLanguage()
    -- Check saved setting
    if OculusStorage and OculusStorage.Language and LOCALES[OculusStorage.Language] then
        return OculusStorage.Language
    end
    -- Fall back to client locale
    local clientLocale = GetLocale()
    return LOCALES[clientLocale] and clientLocale or "enUS"
end

-- Set Language
function Oculus:SetLanguage(lang)
    if not LOCALES[lang] then
        return false
    end
    if not OculusStorage then
        OculusStorage = {}
    end
    OculusStorage.Language = lang
    return true
end

-- Metatable for L - dynamically gets strings based on current language
setmetatable(L, {
    __index = function(_, key)
        local lang = Oculus:GetLanguage()
        local strings = LOCALES[lang] or LOCALES["enUS"]
        return strings[key] or LOCALES["enUS"][key] or key
    end,
})
