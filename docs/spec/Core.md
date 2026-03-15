# Oculus - Core Module

## 역할

전체 애드온 관리, 공통 기능 제공

## 기능

- 모듈 등록/활성화/비활성화 시스템
- ESC > 인터페이스 > 애드온 설정 패널 (모듈별 서브패널 포함)
- 프로필 내보내기/가져오기 (Base64 직렬화)
- 다국어 지원 (enUS, koKR)
- 로깅 시스템 (SavedVariables에 저장)
- 공통 유틸리티 (Base64, 직렬화)

## 슬래시 커맨드

```
/oculus                   - 설정 UI 열기
/oculus test              - 전체 테스트 모드
/oculus test <module>     - 특정 모듈 테스트
```

## SavedVariables

```lua
-- Core (OculusDB)
OculusDB = {
    Language = "enUS",  -- 언어 설정
    Modules = {
        UnitFrames = true,
        RaidFrames = true,
        ArenaFrames = false,
    },
}

-- UnitFrames (OculusUnitFramesStorage)
OculusUnitFramesStorage = { ... }

-- RaidFrames (OculusRaidFramesStorage)
OculusRaidFramesStorage = { ... }

-- 공통 로그 (OculusLogs)
OculusLogs = { "[2026-01-01 00:00:00] [Core] Initialized", ... }
```

## 파일 구조

```
Oculus/
├── Oculus.toc
├── Core.lua           -- 메인 초기화, 모듈 관리 (RegisterModule, EnableModule, DisableModule)
├── Config.lua         -- 설정 패널 UI (모듈 On/Off, 언어 변경, 프로필 내보내기/가져오기)
├── Utils.lua          -- 공통 유틸리티 (Base64, Serialize/Deserialize, ExportProfile/ImportProfile)
├── Localization.lua   -- 다국어 처리 (enUS/koKR, 150+ 문자열)
└── Logger.lua         -- 로그 시스템 (SavedVariables 저장, 최대 500개)
```

## 모듈 관리 API

```lua
-- 모듈 등록 (각 모듈의 toc 로드 완료 후 호출)
Oculus:RegisterModule("UnitFrames", UnitFrames)

-- 모듈 활성화/비활성화
Oculus:EnableModule("UnitFrames")
Oculus:DisableModule("RaidFrames")

-- 모듈 상태 확인
Oculus:IsModuleEnabled("UnitFrames")  -- true/false
```

## 로거 API

```lua
-- 모든 로그는 logDebug()를 통해서만 출력 (print() 직접 호출 금지)
_G.Oculus.Logger:Log("ModuleName", "SubModule", "message")
_G.Oculus.Logger:Clear()
```

## 설정 패널 구조

```
ESC > 인터페이스 > 애드온 > Oculus
├── [메인 패널]
│   ├── 버전 정보
│   ├── 언어 선택 (enUS / koKR)
│   └── 프로필 내보내기 / 가져오기
├── [Unit Frames 서브패널]   → UnitFrames 모듈이 채움
├── [Raid Frames 서브패널]   → RaidFrames 모듈이 채움
└── [Arena Frames 서브패널]  → ArenaFrames 모듈이 채움 (미구현)
```

## 이벤트 흐름

```
ADDON_LOADED  → 스토리지 초기화, Core 설정 패널 생성
PLAYER_LOGIN  → 활성화된 모듈 순차적으로 Enable()
```
