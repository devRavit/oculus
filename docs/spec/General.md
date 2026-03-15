# Oculus_General

## 역할

블리자드 기본 프레임의 위치를 드래그로 재배치하고 저장합니다.

## 지원 프레임

| 프레임명 | 대상 | 클래스 |
|----------|------|--------|
| `TotemFrame` | 토템바 | 주술사 |
| `DruidBarFrame` | 드루이드 바 (나무정령 등) | 드루이드 |

## 동작 방식

### 위치 이동

1. ESC > AddOns > Oculus > General 패널 열기
2. "잠금 해제" 버튼 클릭
3. 녹색 오버레이가 표시된 프레임을 드래그
4. "잠금" 버튼으로 위치 저장

### 위치 저장/복원

- 위치는 `OculusGeneralStorage.Frames[frameName].{x, y}` 에 저장
- `PLAYER_ENTERING_WORLD` 이벤트 시 복원 (0.2초 지연)
- `PLAYER_REGEN_ENABLED` (전투 종료) 시 복원
- 블리자드 업데이트 함수 hook으로 Blizzard가 위치를 초기화해도 재적용

### 전투 제한

- `InCombatLockdown()` 상태에서는 프레임 이동 불가
- 전투 중 "잠금 해제" 버튼 비작동

## DB 구조

```lua
OculusGeneralStorage = {
    Frames = {
        TotemFrame = { x = 100, y = 200 },    -- nil이면 기본 위치
        DruidBarFrame = { x = 300, y = 150 },
    },
}
```

## 파일 구조

```
Oculus_General/
├── Oculus_General.toc
├── General.lua    -- 메인 모듈 (프레임 이동, 저장, 복원)
└── Config.lua     -- 설정 UI (잠금/해제 버튼, 초기화 버튼)
```

## API

| 함수 | 설명 |
|------|------|
| `General:UnlockFrames()` | 드래그 핸들 표시, 이동 가능 상태 |
| `General:LockFrames()` | 드래그 핸들 숨김 |
| `General:ResetPosition(frameName)` | 특정 프레임 위치 초기화 |
| `General:ResetAllPositions()` | 전체 프레임 위치 초기화 |
| `General:GetManagedFrames()` | 관리 중인 프레임 목록 반환 |
