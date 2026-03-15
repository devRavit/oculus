# Oculus_ArenaFrames

> ⚠️ **미구현** - 명세서만 존재하며 코드가 없는 상태

## 역할

아레나 적 프레임 강화

## 계획된 기능

### 1. 프레임 정렬
- 힐러/딜러/탱 순서 자동 정렬
- 수동 정렬 옵션
- 드래그로 위치 조정

### 2. 버프/디버프 필터
- 적에게 걸린 중요 버프 표시 (트링켓, 방어기 등)
- 내가 건 디버프 강조
- 우선순위 기반 표시

## 정렬 옵션

| 옵션 | 설명 |
|------|------|
| SPEC | 힐러 > 딜러 순서 |
| CLASS | 클래스 알파벳 순서 |
| MANUAL | 사용자 지정 |
| NONE | 정렬 안 함 (기본) |

## 계획된 설정 옵션

```lua
Oculus_ArenaFramesDB = {
    enabled = true,
    sorting = {
        enabled = true,
        mode = "SPEC",  -- SPEC, CLASS, MANUAL, NONE
    },
    auras = {
        enabled = true,
        iconSize = 35,
        showMyDebuffs = true,
        myDebuffGlow = true,
    },
    layout = {
        scale = 1.0,
        spacing = 5,
        growDirection = "DOWN",
    },
}
```

## 계획된 파일 구조

```
Oculus_ArenaFrames/
├── Oculus_ArenaFrames.toc
├── ArenaFrames.lua    -- 메인 초기화, 프레임 후킹
├── Auras.lua          -- Aura 필터링
└── Sorting.lua        -- 프레임 정렬 로직
```
