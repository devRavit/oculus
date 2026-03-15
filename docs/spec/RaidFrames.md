# Oculus_RaidFrames

## 역할

파티/레이드 프레임 강화

## 기능

### 1. 버프/디버프 필터
- 파티원에게 걸린 중요 CC/디버프 표시
- 아이콘 크기 조절 (설정 UI)
- 타이머 표시 (남은 시간)
- 만료 경고 (25% 미만 시 빨간 테두리 글로우)
- Masque 스킨 지원

### 2. 아군 쿨다운 트래킹 (예정)
- 파티원 주요 쿨다운 표시
- 방어기, 유틸리티 스킬 추적
- 남은 시간 표시

### 3. 적 시전 알림 (예정)
- 적이 아군에게 시전 시 해당 프레임 하이라이트
- 아이콘 + 타이머 표시
- 메즈/딜 스킬 구분 (색상 또는 테두리)

## 설정 옵션

### Auras (버프/디버프)

| 설정 | 타입 | 기본값 | 설명 | UI |
|------|------|--------|------|-----|
| Enabled | bool | true | 기능 활성화 | Checkbox |
| BuffSize | number | 20 | 버프 아이콘 크기 | Slider (10-40) |
| DebuffSize | number | 24 | 디버프 아이콘 크기 | Slider (10-50) |
| MaxBuffs | number | 3 | 표시할 버프 최대 개수 | Slider |
| MaxDebuffs | number | 3 | 표시할 디버프 최대 개수 | Slider |
| ShowTimer | bool | true | 남은 시간 표시 | Checkbox |
| ExpiringThreshold | number | 0.25 | 만료 경고 임계값 (25%) | Slider (10-50%) |

### Cooldowns (예정)

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| Enabled | bool | false | 기능 활성화 |
| IconSize | number | 20 | 아이콘 크기 |
| Position | string | "BOTTOM" | 표시 위치 |
| TrackedSpells | table | {} | 추적할 스킬 목록 |

### CastAlert (예정)

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| Enabled | bool | false | 기능 활성화 |
| FlashDuration | number | 0.5 | 하이라이트 지속시간 |
| ShowIcon | bool | true | 시전 아이콘 표시 |
| CCColor | color | 보라 | CC 스킬 색상 |
| DamageColor | color | 빨강 | 딜 스킬 색상 |
| UtilityColor | color | 노랑 | 유틸리티 스킬 색상 |

## 설정 UI

ESC > 인터페이스 > 애드온 > Oculus > Raid Frames

- **Buff Size**: 슬라이더 (10-40)
- **Debuff Size**: 슬라이더 (10-50)
- **Show Timer**: 체크박스
- **Expiring Warning (%)**: 슬라이더 (10-50%)
- **Preview**: 프리뷰 버튼

## 외부 연동

### Masque
- OptionalDeps: Masque
- 버프/디버프 아이콘에 Masque 스킨 적용
- Masque 그룹: "Oculus" > "Raid Auras"

## 파일 구조

```
Oculus_RaidFrames/
├── Oculus_RaidFrames.toc
├── RaidFrames.lua     -- 메인 초기화
├── Auras.lua          -- Aura 필터링 + 타이머 + Masque
├── Config.lua         -- 설정 UI
├── Cooldowns.lua      -- 쿨다운 트래킹 (예정)
└── CastAlert.lua      -- 적 시전 알림 (예정)
```

## 프리뷰 모드

- `/oculus test raidframes` 또는 설정 UI의 Preview 버튼
- 가짜 파티 프레임 5개 표시
- 버프/디버프 아이콘 + 타이머 시뮬레이션
- 만료 경고 효과 시뮬레이션

---

## Progress

### Phase 1: 기본 구조 ✅
- [x] Oculus_RaidFrames.toc 생성
- [x] RaidFrames.lua 초기화
- [x] 파티 프레임 후킹

### Phase 2: Aura 표시 ✅
- [x] Auras.lua 구현
- [x] 아이콘 크기 조절
- [x] 타이머 표시
- [x] 만료 경고 (빨간 테두리 글로우)
- [x] Masque 지원

### Phase 3: 설정 UI ✅
- [x] Config.lua 구현
- [x] 슬라이더/체크박스 컨트롤
- [ ] 프리뷰 기능

### Phase 4: 쿨다운 트래킹
- [ ] Cooldowns.lua 구현
- [ ] UNIT_SPELLCAST_SUCCEEDED 이벤트 연동
- [ ] 쿨다운 타이머 계산

### Phase 5: Cast Alert
- [ ] CastAlert.lua 구현
- [ ] UNIT_SPELLCAST_START 이벤트 연동
- [ ] 프레임 하이라이트 효과
- [ ] 메즈/딜 구분 색상

### Phase 6: 테스트 모드
- [ ] 가짜 데이터 시뮬레이션
- [ ] Preview 기능 구현
