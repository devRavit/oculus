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

| 모듈 | 설명 | 구현 상태 | 명세서 |
|------|------|-----------|--------|
| **Oculus** | 코어 (모듈 관리, 설정 UI, 공통 기능) | ✅ 구현 완료 | [Core.md](./Core.md) |
| **Oculus_UnitFrames** | Player/Target/Focus 포트레이트 CC/Aura 오버레이 | ✅ 구현 완료 | [UnitFrames.md](./UnitFrames.md) |
| **Oculus_RaidFrames** | 파티 프레임 버프/디버프 커스터마이징 | ✅ 구현 완료 | [RaidFrames.md](./RaidFrames.md) |
| **Oculus_ArenaFrames** | 아레나 프레임 정렬 + 버프/디버프 | ❌ 미구현 | [ArenaFrames.md](./ArenaFrames.md) |
| **Oculus_General** | 블리자드 프레임 위치 이동 (토템바, 드루이드 바) | ✅ 구현 완료 | [General.md](./General.md) |

## 프로젝트 구조

```
oculus/
├── docs/
│   ├── spec/
│   │   ├── Overview.md
│   │   ├── Core.md
│   │   ├── UnitFrames.md
│   │   ├── RaidFrames.md
│   │   ├── ArenaFrames.md
│   │   ├── General.md
│   │   └── Versioning.md
│   ├── ARCHITECTURE.md
│   └── CODE_STYLE.md
├── Oculus/
│   ├── Oculus.toc
│   ├── Core.lua
│   ├── Config.lua
│   ├── Utils.lua
│   ├── Localization.lua
│   └── Logger.lua
├── Oculus_UnitFrames/
│   ├── Oculus_UnitFrames.toc
│   ├── UnitFrames.lua
│   ├── Auras.lua
│   ├── Spells.lua
│   └── Config.lua
├── Oculus_RaidFrames/
│   ├── Oculus_RaidFrames.toc
│   ├── RaidFrames.lua
│   ├── Auras.lua
│   ├── Config.lua
│   ├── ConfigFrameTab.lua
│   ├── ConfigBuffTab.lua
│   └── ConfigDebuffTab.lua
├── Oculus_General/
│   ├── Oculus_General.toc
│   ├── General.lua
│   └── Config.lua
├── README.md
├── CHANGELOG.md
├── CLAUDE.md
└── .gitignore
```

## 기술 스펙

### 12.0 API 대응

**Secret Values 처리** (pcall 패턴 사용):
```lua
-- spellId, icon 등 전투 API 반환값은 직접 연산 불가
local success = pcall(function() return spellId + 0 end)
local isSecret = not success

-- 안전한 UI 전달
frame.Icon:SetTexture(aura.icon)  -- 직접 전달 ✅
local count = aura.spellId + 1    -- 산술 연산 ❌
```

**주요 이벤트**:
```lua
UNIT_AURA                  -- 버프/디버프 변경
PLAYER_TARGET_CHANGED      -- 타겟 변경
PLAYER_FOCUS_CHANGED       -- 포커스 변경
```

### 성능 최적화

- 이벤트 기반 업데이트 (폴링 없음)
- Auras: 0.1초 주기 ticker로 타이머 갱신
- 불필요한 업데이트 방지

## 코딩 컨벤션

> 상세한 코딩 컨벤션은 [CLAUDE.md](../../CLAUDE.md#lua-coding-conventions) 참조

### 요약

| 대상 | 규칙 | 예시 |
|------|------|------|
| 모듈/클래스 | PascalCase | `UnitFrames`, `RaidFrames` |
| 함수 | PascalCase (모듈 메서드) / camelCase (로컬) | `Auras:Enable()`, `createIconFrame()` |
| 지역 변수 | camelCase | `iconFrames`, `currentUnit` |
| 상수 | LOUD_SNAKE_CASE | `TRACKED_UNITS`, `CATEGORY_COLORS` |
| 이벤트 핸들러 | camelCase | `onEvent`, `eventHandlers` |

## 참고 자료

- [WoW 12.0 API 변경사항](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
- [BigDebuffs GitHub](https://github.com/jordonwow/bigdebuffs)
- [Blizzard UI Source](https://github.com/Gethe/wow-ui-source)
