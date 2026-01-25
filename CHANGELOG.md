# Changelog

All notable changes to Oculus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
