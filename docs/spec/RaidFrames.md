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
        MaxCount = 3,           -- 최대 표시 개수
        AnchorPoint = "TOPLEFT",
        RelativePoint = "TOPLEFT",
        OffsetX = 0,
        OffsetY = 0,
        ShowTimer = true,
        ExpiringThreshold = 0.25,  -- 만료 경고 임계값 (25%)
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
- Masque 그룹: `"Oculus" > "Raid Auras"`

## 파일 구조

```
Oculus_RaidFrames/
├── Oculus_RaidFrames.toc
├── RaidFrames.lua        -- 모듈 초기화, 스토리지 관리, Auras 서브모듈 제어
├── Auras.lua             -- CompactUnitFrame 후킹, 버프/디버프 렌더링, 타이머, Masque
├── Config.lua            -- 설정 패널 생성, 탭 컨테이너 구성
├── ConfigFrameTab.lua    -- Frame 탭 UI
├── ConfigBuffTab.lua     -- Buff 탭 UI
└── ConfigDebuffTab.lua   -- Debuff 탭 UI
```

## 기술 구현 메모

### CompactUnitFrame 후킹

Blizzard의 `CompactUnitFrame_UpdateAuras` 함수를 후킹하여 기본 버프/디버프 업데이트 직후 커스터마이징 적용.

### 업데이트 방식

- 0.1초 주기 ticker로 만료 경고 상태 지속 갱신
- `UNIT_AURA` 이벤트로 즉각 업데이트
