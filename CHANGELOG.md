# Changelog

All notable changes to Oculus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-03-26

### Added
- **RaidFrames**: 타이머 폰트 크기 슬라이더 추가 (Timer Settings)
- **RaidFrames**: 만료 경고 테두리 크기 슬라이더 추가 — 아이콘 주변 glow 크기 조절 (Timer Settings)

### Changed
- **RaidFrames**: 버프 아이콘 크기 설정 제거 — 고정값(20px)으로 변경
- **RaidFrames**: 버프 다중 행 표시 수정 — PerRow 설정에 따라 행이 올바르게 쌓이도록 개선
- **RaidFrames**: 만료 경고 테두리를 padding 기반으로 변경 — 아이콘 밖으로 glow가 표시되도록 수정
- **RaidFrames**: OnUpdate에서 폰트 크기 변경 시에만 SetFont 호출하도록 최적화

### Removed
- **RaidFrames**: 버프 아이콘 크기(Buff Icon Size) 설정 및 관련 코드 제거

---

## [0.2.5] - 2026-03-22

### Changed
- **RaidFrames**: 해제 오버레이 숨김 설정을 Debuff 탭에서 Frame 탭으로 이동
- **RaidFrames**: 해제 아이콘 숨기기 수정 — 잘못된 글로벌 참조 제거, `frame.dispelDebuffFrames` 배열 사용으로 교체
- **RaidFrames**: Debuff 탭을 남은 시간 표시(Show Timer) 설정만 유지하도록 간소화

### Removed
- **RaidFrames**: 디스펠 테두리 숨김(Hide Dispel Border), 디스펠 테두리 크기(Dispel Border Size) 설정 및 관련 코드 제거
- **RaidFrames**: 디버프 아이콘 크기, 최대 개수, 행당 개수, 앵커, 간격 설정 및 관련 렌더링 코드 제거

---

## [0.2.0] - 2026-01-25

### Added
- **RaidFrames**: Two-level navigation UI (tabs + sidebar categories) for better organization
- **RaidFrames**: Max Buffs/Debuffs settings - control total number of auras displayed (1-15 range)
- **RaidFrames**: Modern slider UI with visual progress bar and editable value input
- **RaidFrames**: Modern checkbox UI with left-aligned labels and clickable rows
- **RaidFrames**: Split Config.lua into modular tab files (ConfigFrameTab, ConfigBuffTab, ConfigDebuffTab)

### Changed
- **RaidFrames**: Renamed "어그로 테두리 숨김" → "어그로 오버레이 숨김" for clarity
- **RaidFrames**: Separated "버프 총 개수" (Max Buffs) from "행당 버프 개수" (Buffs Per Row) - distinct functionality
- **RaidFrames**: Timer Settings moved to separate category in Buff tab

### Removed
- **RaidFrames**: Removed "커스텀 위치 사용" option (unnecessary)

## [0.1.1] - 2026-01-25

### Fixed
- **RaidFrames**: Fixed edit mode compatibility - addon now properly deactivates during edit mode to prevent frame size conflicts
- **RaidFrames**: Fixed secret value errors during combat when accessing protected frame properties
- **RaidFrames**: Fixed Masque integration errors by preventing registration during combat

### Removed
- **RaidFrames**: Removed Frame Scale feature (conflicted with Blizzard's edit mode scaling)

### Changed
- **RaidFrames**: Improved code style - eliminated abbreviations (cfg → configuration, rf → raidFrames, auraData → aura)
- **RaidFrames**: Removed deprecated DB terminology - unified to Storage naming convention
- **RaidFrames**: Removed GetDB() and DebugDB() backward compatibility aliases

### Added
- **RaidFrames**: Added Buff Spacing and Debuff Spacing controls (0-10 pixels)

## [0.1.0] - 2026-01-24

### Added
- Core module with module registry system
- Settings panel (ESC menu integration)
- Profile Export/Import with Base64 encoding
- Localization support (English/Korean)
- Language selection dropdown with reload confirmation
- Slash commands: `/oculus`, `/oc`

### Core Features
- Module enable/disable system
- SavedVariables (OculusDB)
- Sub-panels for each module (UnitFrames, RaidFrames, ArenaFrames)
