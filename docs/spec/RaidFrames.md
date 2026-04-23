# Oculus_RaidFrames

## 역할

파티/레이드 CompactUnitFrame의 버프/디버프 표시 방식 커스터마이징

## 기능

### 1. 버프/디버프 커스터마이징 ✅
- 파티원 버프/디버프 아이콘 크기 및 최대 개수 조절
- 아이콘 위치 앵커 설정 (TOPLEFT, BOTTOMRIGHT 등)
- 타이머 표시
- 만료 경고: 남은 시간이 임계값(기본 25%) 미만 시 노란색 테두리 글로우
- Masque 스킨 지원 (옵션 의존성)

### 2. 프레임 커스터마이징 ✅
- 역할 아이콘 숨기기
- 이름 텍스트 숨기기
- 어그로 테두리 숨기기
- 파티 타이틀 숨기기

### 3. 쿨다운 트래킹 ❌ (미구현)

### 4. 적 시전 알림 ❌ (미구현)

## 설정 옵션

```lua
OculusRaidFramesStorage = {
    Enabled = true,
    Frame = {
        HideRoleIcon = false,
        HideName = false,
        HideAggroBorder = false,
        HidePartyTitle = false,
    },
    Buff = {
        Enabled = true,
        Size = 20,              -- 버프 아이콘 크기 (10~40)
        MaxCount = 3,
        AnchorPoint = "TOPLEFT",
        RelativePoint = "TOPLEFT",
        OffsetX = 0,
        OffsetY = 0,
        ShowTimer = true,
        ExpiringThreshold = 0.25,
    },
    Debuff = {
        Enabled = true,
        Size = 24,              -- 디버프 아이콘 크기 (10~50)
        MaxCount = 3,
        AnchorPoint = "BOTTOMRIGHT",
        RelativePoint = "BOTTOMRIGHT",
        OffsetX = 0,
        OffsetY = 0,
        ShowTimer = true,
        ExpiringThreshold = 0.25,
    },
}
```

## 설정 UI

ESC > 인터페이스 > 애드온 > Oculus > Raid Frames

탭 구조:
- **Frame 탭** (`ConfigFrameTab.lua`): 역할 아이콘, 이름, 어그로 테두리, 파티 타이틀 숨기기
- **Buff 탭** (`ConfigBuffTab.lua`): 버프 크기, 최대 개수, 앵커, 타이머, 만료 경고
- **Debuff 탭** (`ConfigDebuffTab.lua`): 디버프 크기, 최대 개수, 앵커, 타이머, 만료 경고

## 외부 연동

### Masque
- OptionalDeps: Masque
- 버프/디버프 아이콘에 Masque 스킨 적용
- Masque 그룹: "Oculus" > "Raid Auras"

## 파일 구조

```
Oculus_RaidFrames/
├── Oculus_RaidFrames.toc
├── RaidFrames.lua        -- 모듈 초기화, 스토리지 관리, Auras 서브모듈 제어
├── AuraScanner.lua       -- 유닛별 aura 캐시 + UNIT_AURA 델타 + AuraUtil.ProcessAura 필터
├── AuraButton.lua        -- 단일 aura 버튼 (icon/cooldown/count/timer/border/expiring glow)
├── AuraContainer.lua     -- 프레임당 컨테이너 (Scanner + 버프/디버프 버튼 배열 + 레이아웃)
├── Auras.lua             -- 공용 API · hooks · Frame 설정 · Range Fade · Preview
├── Config.lua            -- 설정 패널 생성, 탭 컨테이너 구성
├── ConfigFrameTab.lua    -- Frame 탭 UI
├── ConfigBuffTab.lua     -- Buff 탭 UI
└── ConfigDebuffTab.lua   -- Debuff 탭 UI
```

## 기술 구현 메모

### Aura 파이프라인 (v0.3.0, 12.0.5 대응)

12.0.5에서 Blizzard가 `CompactUnitFrame`의 aura 섹션(전역 `CompactUnitFrame_UpdateAuras`, `frame.buffFrames`/`frame.debuffFrames`, `CompactBuffTemplate`/`CompactDebuffTemplate`, 템플릿 핸들러 등)을 전부 제거함. 기존 hook 재스킨 방식이 완전히 먹통이 되어 Oculus 자체 프레임 풀로 재설계.

```
┌─────────────────────────────────────────────────────────────┐
│ CompactUnitFrame (Blizzard)                                 │
│   ↓ hooksecurefunc("CompactUnitFrame_SetUnit")              │
│ Auras.wireFrame(frame)                                      │
│   ↓ AuraContainer.attach(frame) / bind(unit)                │
│ AuraContainer (Oculus)                                      │
│   ├─ scanner : AuraScanner (유닛별 aura 캐시)                │
│   │    ↑ UNIT_AURA(unit, updateInfo) 델타                    │
│   │    ↑ AuraUtil.ForEachAura 초기 스냅샷                    │
│   │    ↑ AuraUtil.ProcessAura 필터 (블리자드 기준)           │
│   └─ buffButtons / debuffButtons : AuraButton[]             │
│        ↑ 레이아웃: Auras:CalculateAnchorOffset              │
│        ↑ OnUpdate(0.1s throttle) : 카운트다운 + 임박 테두리 │
│        ↑ Masque: Oculus/Raid Auras 그룹 자동 등록           │
└─────────────────────────────────────────────────────────────┘
```

### 업데이트 방식 (D4-B 확정)

- Aura 변경은 `UNIT_AURA(unit, updateInfo)` 이벤트의 델타(`addedAuras` / `updatedAuraInstanceIDs` / `removedAuraInstanceIDs`)로 반영
- 남은 시간 텍스트는 **활성 버튼에만** `OnUpdate` 스크립트를 걸어 카운트다운 (만료/해제 시 핸들러 자동 해제 → 0 비용)
- OnUpdate 텍스트 갱신은 0.1s 스로틀
- 전역 0.1s ticker 없음

### 필터 규칙 (Blizzard 기준 유지)

`AuraUtil.ProcessAura(aura, displayOnlyDispellableDebuffs=false, ignoreBuffs=false, ignoreDebuffs=false, ignoreDispelDebuffs=true)` 반환값 매핑:

| ProcessAura 결과 | 처리 |
|------------------|------|
| `AuraUpdateChangedType.Buff`   | 버프 목록 추가 (`AuraUtil.DefaultAuraCompare` 정렬) |
| `AuraUpdateChangedType.Debuff` | 디버프 목록 추가 (`AuraUtil.UnitFrameDebuffComparator` 정렬) |
| `AuraUpdateChangedType.Dispel` | 디버프 목록 추가 (디스펠 타입 색상 border) |
| `AuraUpdateChangedType.None`   | 무시 |

### Private Aura

현재(v0.3.0) private aura는 Blizzard_PrivateAurasUI의 기본 anchor로 렌더됨 (`AuraUtil.ForEachAura`는 private aura를 반환하지 않으므로 Oculus 파이프라인에는 유입되지 않음). 커스텀 `C_UnitAuras.AddPrivateAuraAnchor` 연동으로 Oculus 슬롯에 맞춰 그리는 것은 후속 릴리스.
