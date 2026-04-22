# Changelog

프로젝트 변경 내역 (최신순)

<!-- CHANGELOG_START -->

## v0.2.6
`2026.04.22 00:00`

WoW 12.0.5 호환성 업데이트 및 버그 수정

- Interface 버전 120000 → 120005 (WoW 12.0.5) 전체 모듈 적용
- RaidFrames: `CompactUnitFrame_UpdateAuras` 전역 함수 제거로 인한 에러 수정 — `CompactUnitFrameMixin` 메서드 fallback 추가
- RaidFrames: `CompactUnitFrame_SetUnit`, `CompactUnitFrame_UpdateCenterStatusIcon` 동일한 전역/mixin 분기 처리 적용

---

## v0.2.2
`2026.02.19 00:00`

Claude Code 불필요한 파일 탐색 방지를 위한 .claudeignore 추가

- debug.log, scripts/ 등 불필요한 파일 제외

---

<!-- CHANGELOG_END -->
