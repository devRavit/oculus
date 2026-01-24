# Oculus - Overview

> 라틴어 "Oculus" = 눈 (Eye)
> PvP 전투에서 모든 것을 볼 수 있게 해주는 애드온

## 개요

Oculus는 World of Warcraft Midnight (12.0) PvP를 위한 통합 애드온 스위트입니다.
코어 모듈과 3개의 독립적인 프레임 모듈로 구성되어 있으며, 각 모듈은 개별적으로 활성화/비활성화할 수 있습니다.

## 목표

- 일반 PvP 유저들이 표준으로 사용하는 애드온
- 직관적이고 깔끔한 UI
- 12.0 API에 완벽 대응

## 모듈 구성

| 모듈 | 설명 | 명세서 |
|------|------|--------|
| **Oculus** | 코어 (모듈 관리, 공통 설정) | [Core.md](./Core.md) |
| **Oculus_UnitFrames** | Player/Target/Focus 버프/디버프 필터 | [UnitFrames.md](./UnitFrames.md) |
| **Oculus_RaidFrames** | 파티 버프/디버프 + 쿨다운 + 시전 알림 | [RaidFrames.md](./RaidFrames.md) |
| **Oculus_ArenaFrames** | 아레나 프레임 정렬 + 버프/디버프 | [ArenaFrames.md](./ArenaFrames.md) |

## 프로젝트 구조

```
oculus/
├── docs/spec/
│   ├── Overview.md
│   ├── Core.md
│   ├── UnitFrames.md
│   ├── RaidFrames.md
│   └── ArenaFrames.md
├── Oculus/
│   ├── Oculus.toc
│   ├── Core.lua
│   ├── ModuleManager.lua
│   ├── Config.lua
│   ├── Constants.lua
│   ├── Utils.lua
│   └── TestMode.lua
├── Oculus_UnitFrames/
├── Oculus_RaidFrames/
├── Oculus_ArenaFrames/
├── README.md
└── .gitignore
```

## 기술 스펙

### 12.0 API 대응

**Secret Values 처리**:
```lua
local function GetSafeAuraInfo(unit, index)
    local aura = C_UnitAuras.GetAuraDataByIndex(unit, index)
    if aura and not issecretvalue(aura.spellId) then
        return aura
    end
    return nil
end
```

**주요 이벤트**:
```lua
UNIT_AURA                  -- 버프/디버프 변경
UNIT_SPELLCAST_START       -- 시전 시작
UNIT_SPELLCAST_STOP        -- 시전 종료
ARENA_OPPONENT_UPDATE      -- 아레나 상대 변경
GROUP_ROSTER_UPDATE        -- 파티/레이드 변경
```

### 성능 최적화

- 이벤트 쓰로틀링 (0.1초)
- 불필요한 업데이트 방지
- 테이블 재사용

## 코딩 컨벤션

### 네이밍

| 타입 | 스타일 | 예시 |
|------|--------|------|
| 함수 | PascalCase | `GetPlayerHealth()`, `UpdateFrame()` |
| 변수 | PascalCase | `PlayerHealth`, `IconSize` |
| 상수 | UPPER_SNAKE_CASE | `MAX_ICONS`, `DEFAULT_SIZE` |
| 파일 | PascalCase | `Core.lua`, `ModuleManager.lua` |
| 테이블/모듈 | PascalCase | `Oculus`, `OculusDB` |
| 이벤트 | UPPER_SNAKE_CASE | `UNIT_AURA`, `PLAYER_LOGIN` |

### 규칙

- `local` 사용 권장 (전역 오염 방지)
- 함수는 동사로 시작 (`Get`, `Set`, `Update`, `Create`, `Handle`)
- 불리언 변수는 `Is`, `Has`, `Can` prefix (`IsEnabled`, `HasAura`)
- 콜백/핸들러는 `On` prefix (`OnEvent`, `OnClick`)

## 참고 자료

- [WoW 12.0 API 변경사항](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
- [BigDebuffs GitHub](https://github.com/jordonwow/bigdebuffs)
- [OmniCD CurseForge](https://www.curseforge.com/wow/addons/omnicd)
