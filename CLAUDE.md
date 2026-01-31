# 메이 마피아 (Mei Mafia) - 오버워치 워크샵 프로젝트

오버워치 워크샵에서 실행되는 마피아 게임입니다. 메이 캐릭터를 사용하여 6~12명이 플레이합니다.

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 버전 | 3.8.01 |
| 플랫폼 | 오버워치 워크샵 |
| 플레이어 | 6~12명 |
| 영웅 | 메이 (고정) |

---

## 코드 작성 규칙

### 필수 원칙
- 실제 동작하는 코드만 작성 (모킹 금지)
- 요청한 기능만 구현 (오버엔지니어링 금지)
- 기능을 명확히 나타내는 이름 사용
- 기존 한글 코드를 승인 없이 영어로 변경하지 않음

### 데이터 중심 설계
- 모든 상태는 글로벌/플레이어 변수에 저장
- 복잡한 로직은 서브루틴으로 분리
- 비동기 방식으로 능력 사용과 결과 처리

---

## 워크샵 스크립트 구조

```
파일 구조:
├── settings      # 게임 설정 (모드, 맵, 영웅)
├── variables     # 글로벌/플레이어 변수 선언
├── subroutines   # 서브루틴 목록
└── rules         # 게임 로직 (이벤트 + 조건 + 액션)
```

### Rule 기본 구조
```
rule("규칙 이름")
{
    event { Ongoing - Global; }           // 이벤트 타입
    condition { Global.변수 == 값; }       // 실행 조건 (AND 연산)
    action { /* 실행할 액션들 */ }         // 실행 내용
}
```

### 이벤트 타입
| 이벤트 | 설명 |
|--------|------|
| `Ongoing - Global` | 전역 이벤트 (게임 전체) |
| `Ongoing - Each Player` | 플레이어별 이벤트 |
| `Subroutine` | 서브루틴 호출 |

---

## 게임 흐름 (Squence)

```
[0] 대기 → [1] 준비 (6인 이상) → [2] 게임 진행 → [3] 승패 결정 → [4] 종료
```

| Squence | 상태 | 설명 |
|---------|------|------|
| 0 | 대기 | 플레이어 참여 대기 |
| 1 | 준비 | 6인 이상 참여 시, 직업 선정 |
| 2 | 게임 진행 | 낮/밤 사이클, 투표, 능력 사용 |
| 3 | 승패 결정 | 승리 조건 충족 |
| 4 | 종료 | 게임 종료 |

---

## 게임 모드

| 모드 | 설명 |
|------|------|
| 노말 모드 | 기본 모드, 인원에 따라 특수 직업 추가 |
| 클래식 모드 | 기본 직업 위주 (마피아, 경찰, 의사, 시민) |
| 하드 모드 | 5개 이상 시민 특직 + 마피아 특직 + 3세력 필요 |

---

## 팀 & 직업

### 시민 팀 (Team == 1)
| 분류 | 직업 |
|------|------|
| 기본 | 시민 |
| 중직 | 경찰, 의사 |
| 특직 | 탐정, 영매, 건달, 도굴꾼, 기자, 정치인, 성직자, 군인, 테러리스트, 흑기사, 관찰자 |

### 마피아 팀 (Team == 2)
| 분류 | 직업 |
|------|------|
| 기본 | 마피아 |
| 특직 | 스파이, 마담, 도둑, 짐승 인간, 사기꾼, 기계 인간 |

### 3세력 (Team == 3)
독자적인 승리 조건을 가진 세력

---

## 주요 변수

### 글로벌 변수
| 변수 | 용도 |
|------|------|
| `Global.Squence` | 게임 흐름 단계 |
| `Global.Day` | 현재 날짜 |
| `Global.Time` | 시간 (낮/밤) |
| `Global.Players` | 전체 플레이어 배열 |
| `Global.Live_players` | 생존 플레이어 배열 |
| `Global.Dead_players` | 사망 플레이어 배열 |
| `Global.Roles` | 직업 배열 |
| `Global.Game_mode` | 게임 모드 |

### 플레이어 변수
| 변수 | 용도 |
|------|------|
| `player.Role` | 직업명 (문자열) |
| `player.Team` | 소속 팀 (1: 시민, 2: 마피아, 3: 3세력) |
| `player.Dead` | 사망 여부 |
| `player.Power` | 능력 종류 |
| `player.Power_able_day` | 능력 사용 가능 시간 |
| `player.Power_able_left` | 남은 능력 횟수 |
| `player.Ability` | 능력 사용 상태 |
| `player.Target` | 능력 대상 |
| `player.Condition` | 상태 이상 배열 |

---

## 주요 서브루틴

| 서브루틴 | 기능 |
|----------|------|
| `Role_division` | 직업 선정 (모드별 분기) |
| `Role_division_nomal_mode` | 노말 모드 직업 배분 |
| `Role_division_classic_mode` | 클래식 모드 직업 배분 |
| `Role_division_hard_mode` | 하드 모드 직업 배분 |
| `Citizen_SR_picking` | 시민 특직 랜덤 선정 |
| `Mafia_SR_picking` | 마피아 특직 랜덤 선정 |
| `TF_picking` | 3세력 선정 |
| `Player_setting` | 플레이어 초기 설정 |
| `Message` | 메시지 표시 |
| `Create_soul` | 유령 생성 |
| `Role_guide` | 직업 가이드 표시 |

---

## 워크샵 문법 참고

### 조건 비교
```
== (같음), != (다름), < (미만), <= (이하), > (초과), >= (이상)
```

### 배열 조작
```
Append To Array        # 배열에 추가
Remove From Array      # 배열에서 제거
Filtered Array         # 조건 필터링
Randomized Array       # 무작위 섞기
Count Of               # 배열 길이
Array Contains         # 포함 여부
```

### 플레이어 참조
```
Event Player           # 이벤트 발생 플레이어
Current Array Element  # 현재 배열 요소
All Players(All Teams) # 모든 플레이어
Host Player            # 호스트
```

### 흐름 제어
```
If / Else If / Else / End
While / End
For Global Variable / End
Wait(초, Ignore Condition)
Call Subroutine(서브루틴명)
Loop / Loop If Condition Is True
Skip / Skip If
```

---

## 답변 규칙

- 묻는 질문에만 답변
- 코드 작성 외 답변은 한글로 작성
- 결정의 의도와 목적을 설명
- 당신은 시니어 게임 프로그래머로서 주니어와 함께 마피아 게임을 개발

---

## 참고 자료

- [Workshop Syntax Script Database](https://us.forums.blizzard.com/en/overwatch/t/wiki-workshop-syntax-script-database/335011)
- 유튜브: 우비 WWOOBEE
- 네이버: 우비의 워크샵
