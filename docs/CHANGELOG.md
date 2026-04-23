# Changelog

프로젝트 변경 내역 (최신순)

<!-- CHANGELOG_START -->

## v0.3.0
`2026.04.23 22:00`

RaidFrames: WoW 12.0.5 aura 파이프라인 전면 재작성 (Oculus 자체 프레임 풀)

- 12.0.5에서 Blizzard가 `CompactUnitFrame_UpdateAuras` / `frame.buffFrames` / `frame.debuffFrames` / `CompactBuffTemplate` 등 aura 섹션 전체를 삭제 → 기존 hook 기반 재스킨 방식 완전 먹통
- 새 파이프라인: `AuraScanner.lua` (UNIT_AURA 델타 + `AuraUtil.ProcessAura` 필터) + `AuraContainer.lua` (프레임당 버프/디버프 버튼 배열) + `AuraButton.lua` (단일 버튼 + OnUpdate 카운트다운)
- 필터는 `AuraUtil.ProcessAura`에 위임 → "블리자드 기준 표시 규칙" 유지
- 타이머 전략 D4-B 확정: 활성 버튼에만 OnUpdate, 0.1s 스로틀, 만료 시 핸들러 자동 해제
- Masque 연동 유지 (`Oculus / Raid Auras` 그룹)
- 임박 테두리(TrackedSpells × ExpiringThreshold) 유지
- 공용 API 시그니처 보존: `Auras:Enable/Disable/GetSettings/SetSetting/RefreshAllFrames/TogglePreview/CalculateAnchorOffset/ApplyPartyScale`
- Frame 설정 (HideRoleIcon, HideName, HideAggroBorder, HidePartyTitle, HideDispelOverlay), Range Fade, Party Scale은 기존 동작 유지
- Private Aura는 현재 Blizzard_PrivateAurasUI 기본 렌더에 위임 (커스텀 `AddPrivateAuraAnchor` 연동은 후속 릴리스)

---

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
