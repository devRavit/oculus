# Oculus Addon - Development Guidelines

> **Claude 지시사항**: 이 파일의 모든 규칙을 준수할 것.

---

## Checkpoint: 작업 전 필수 읽기

모듈 관련 작업 시 **반드시** 해당 명세서를 먼저 읽을 것.

| 작업 대상 | 명세서 경로 |
|-----------|-------------|
| 전체 구조/개요 | `docs/spec/Overview.md` |
| Core 모듈 | `docs/spec/Core.md` |
| UnitFrames 모듈 | `docs/spec/UnitFrames.md` |
| RaidFrames 모듈 | `docs/spec/RaidFrames.md` |
| ArenaFrames 모듈 | `docs/spec/ArenaFrames.md` |

### 작업 흐름

1. **작업 시작 전**: 관련 명세서 Read 도구로 읽기
2. **구현 중**: 명세서의 구조/API 설계 따르기
3. **구현 완료 후**: 명세서 업데이트 (구현된 내용 반영)

### 명세서 업데이트 규칙

- 새 기능 추가 시: 해당 섹션에 기능 설명 추가
- API 변경 시: 함수 시그니처, 파라미터 업데이트
- 설정 추가 시: DB 구조, 기본값 업데이트

---

## 개발 문서

| 문서 | 경로 | 내용 |
|------|------|------|
| 코드 스타일 | [`docs/CODE_STYLE.md`](docs/CODE_STYLE.md) | 네이밍, 포맷팅, 파일 구조, 리팩토링 체크리스트 |
| 아키텍처 | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | WoW 특화 규칙, 객체지향 설계, 설정 패턴 |

---

## Localization (i18n)

**모든 UI에 표시되는 문자열은 반드시 현지화(Localization) 처리되어야 함**

- 하드코딩된 문자열 사용 금지
- `Oculus.L` 테이블을 통해 현지화된 문자열 사용
- 새로운 문자열 추가 시 `Oculus/Localization.lua`에 enUS, koKR 번역 모두 추가

### 사용 예시

```lua
-- Bad
Button:SetText("Preview Mode")

-- Good
Button:SetText(L["Preview Mode"])
```

### 현지화 파일 구조

- `Oculus/Localization.lua`: 메인 현지화 파일
- enUS (기본값) + koKR 지원
