# aladin_API_search_2.01.py 인수인계 문서

## 개요

알라딘 Open API로 도서를 검색한 뒤, 각 도서의 **목차(TOC)** 를 알라딘 웹 페이지에서 스크래핑하여 엑셀로 저장하는 프로그램.

### 버전 히스토리

| 버전 | 파일명 | 변경 내용 |
|---|---|---|
| 1.00 | `aladin_search.py` | 기본 검색 + 엑셀 저장 |
| 1.02 | `aladin_search_1.02.py` | 목차 스크래핑 추가 (프로토타입) |
| **2.01** | **`aladin_API_search_2.01.py`** | **현재 운영 버전** |

### 사용 환경

- Python 3.13.6
- 필수 패키지: `requests`, `pandas`, `openpyxl`, `beautifulsoup4`

---

## 프로그램 구조

```
main()
 ├── 사용자 입력 (검색어, 카테고리ID)
 ├── search_all()          ← 알라딘 API로 도서 목록 수집
 │    ├── fetch_page()     ← API 1페이지 조회
 │    └── extract_item()   ← 응답 JSON에서 필드 추출
 ├── fetch_toc()           ← 각 도서별 목차 웹 스크래핑
 └── 엑셀 저장 (.xlsx)
```

---

## 핵심 함수 설명

### `fetch_page(query, category_id, start)`

알라딘 ItemSearch API를 호출하여 한 페이지(최대 20건)의 검색 결과를 반환한다.

**API 엔드포인트**
```
http://www.aladin.co.kr/ttb/api/ItemSearch.aspx
```

**주요 파라미터**

| 파라미터 | 값 | 설명 |
|---|---|---|
| `QueryType` | `Author` 또는 `Publisher` | 상단 상수로 전환 가능 |
| `MaxResults` | `20` | API 최대 허용값 |
| `Sort` | `Title` | 제목순 정렬 |
| `output` | `js` | JSON 형식 응답 |
| `CategoryId` | 사용자 입력 | `0`이면 전체 카테고리 |

---

### `extract_item(item)`

API 응답의 각 도서 항목에서 필요한 필드를 딕셔너리로 추출한다.
`seriesInfo`는 중첩 객체이므로 별도로 꺼내서 평탄화(flatten)한다.

**추출 필드 목록 (COLUMNS)**
```
title, link, author, pubDate, description,
isbn, isbn13, itemId, priceSales, priceStandard,
mallType, stockStatus, mileage, cover,
categoryId, categoryName, publisher, salesPoint,
adult, fixedPrice, customerReviewRank,
seriesId, seriesLink, seriesName,
toc   ← 이 시점에서는 빈 문자열, 이후 fetch_toc에서 채움
```

---

### `search_all(query, category_id)`

API를 페이지 단위로 반복 호출하여 전체 검색 결과를 수집한다.

**동작 흐름**
1. 1페이지 조회 → `totalResults`로 전체 건수 파악
2. 2페이지부터 반복 호출 (`start` 파라미터 증가)
3. `item`이 빈 배열이면 종료
4. 각 페이지 사이 `0.3초` 딜레이 (API 부하 방지)

---

### `fetch_toc(session, item_id)` — 핵심 함수

> [!important] 이 함수가 이 버전의 핵심 추가 기능이다.

알라딘 웹 페이지에서 도서의 목차를 스크래핑한다.
**도서 1건당 HTTP 요청 2회**가 필요하다.

#### 왜 2회 요청이 필요한가

알라딘 상품 페이지는 목차를 **JavaScript AJAX로 동적 로딩**한다.
초기 HTML에는 목차가 포함되어 있지 않으며, 페이지 로드 후 별도 엔드포인트를 호출하여 목차를 가져온다.

```
상품 페이지 HTML:
<div class="pContent" id="{hd_ISBN}_Introduce"></div>  ← 빈 div

JavaScript (jquery.lazyload.js):
$j('#{hd_ISBN}_Introduce').loadContent()
  → GET /shop/product/getContents.aspx?ISBN={hd_ISBN}&name=Introduce&type=0
```

#### 요청 1: 상품 페이지 방문

```
GET https://www.aladin.co.kr/shop/wproduct.aspx?ItemId={item_id}
```

**목적 2가지:**
1. **쿠키 획득** — `getContents.aspx`는 해당 상품 페이지를 먼저 방문한 세션의 쿠키가 없으면 빈 응답을 반환한다
2. **`hd_ISBN` 추출** — HTML 내 hidden input에서 알라딘 내부 식별자를 가져온다

```html
<input type="hidden" class="hd_ISBN" value="E392534948" />
```

> [!warning] `hd_ISBN`은 실제 ISBN이 아니다
> 알라딘 내부 식별자이며, 실제 ISBN10/13과 다른 형식이다.
> 예: `E392534948`, `U535235566`, `K902939756`

#### 요청 2: Introduce 콘텐츠 요청

```
GET https://www.aladin.co.kr/shop/product/getContents.aspx
    ?ISBN={hd_isbn}
    &name=Introduce
    &type=0
    &date={현재시간}
```

**필수 헤더:**
- `User-Agent` — 브라우저 UA 문자열 (없으면 차단됨)
- `Referer` — 상품 페이지 URL (없으면 빈 응답)

**응답 HTML 내 목차 위치:**
```html
<!-- 목차 시작 -->
<div class="Ere_prod_mconts_LL">목차</div>
<div class="Ere_prod_mconts_R" id="tocTemplate">
    <div id="div_TOC_All">    ← 전체 목차 (우선 사용)
        <p>1장 제목<br>2장 제목...</p>
    </div>
    <div id="div_TOC_Short">  ← 요약 목차 (All이 없을 때 사용)
        <p>1장 제목<br>2장 제목...</p>
    </div>
</div>
<!-- 목차 끝 -->
```

#### 파싱 우선순위

```python
toc_div = soup.find("div", id="div_TOC_All") or soup.find("div", id="div_TOC_Short")
```

- `div_TOC_All` — 전체 목차 (더보기 클릭 후 내용)
- `div_TOC_Short` — 축약 목차 (기본 노출)
- 둘 다 없으면 → 빈 문자열 반환 (해당 도서에 목차 없음)

---

### `main()`

전체 실행 흐름을 관리한다.

```
1. 검색어 입력 (저자명 또는 출판사명)
2. 카테고리ID 복수 입력 (빈 Enter로 종료)
3. 카테고리별 search_all() 반복
4. 전체 결과에 대해 fetch_toc() 반복
5. DataFrame → 엑셀 저장
```

**출력 파일명 규칙:**
```
aladin_{검색어}_{카테고리ID들}.xlsx
예: aladin_홍길동_351_656.xlsx
```

---

## 설정값 변경 가이드

### 검색 타입 변경

```python
# 8행: 저자검색 ↔ 출판사검색 전환
QUERY_TYPE = "Author"      # 저자검색
QUERY_TYPE = "Publisher"    # 출판사검색
```

### 카테고리 단일 입력 모드

```python
# 12행: True → 복수 입력 / False → 단일 입력
MULTI_CATEGORY = True
```

### 정렬 기준 변경

```python
# 38행 (fetch_page 내부)
"Sort": "Title",          # 제목순
"Sort": "PublishTime",    # 출간일순
```

---

## 실행 예시

```
저자명 입력: 한강
카테고리ID를 하나씩 입력하세요 (입력 완료 시 빈 값으로 Enter):
  카테고리ID: 351
  카테고리ID:

'한강' (카테고리: 351) 검색 중...
총 검색 결과: 8건

목차 수집 중... (총 8건)
  [1/8] 채식주의자 ... 목차: O
  [2/8] 소년이 온다 ... 목차: O
  [3/8] 작별하지 않는다 ... 목차: O
  [4/8] 흰 ... 목차: X          ← 목차가 없는 도서
  ...

완료! 8건 저장 → aladin_한강_351.xlsx
```

---

## 주의사항 및 제약

> [!caution] 성능
> 도서 1건당 약 **1초** 소요 (HTTP 2회 + 딜레이 0.5초).
> 100건이면 약 100초, 대량 검색 시 시간이 오래 걸린다.

> [!caution] 쿠키 의존성
> `getContents.aspx`는 **해당 상품 페이지를 방문한 세션의 쿠키**가 필요하다.
> 다른 상품 페이지의 쿠키로는 동작하지 않는다.
> `requests.Session()`으로 쿠키를 자동 관리한다.

> [!note] 목차가 없는 도서
> 모든 도서에 목차가 있는 것은 아니다. 목차가 없으면 `toc` 컬럼은 빈 값이 된다.

> [!note] API 호출 제한
> 알라딘 Open API 기본 키는 **하루 5,000회** 호출 제한이 있다.
> 목차 스크래핑(웹 요청)은 API 호출 횟수에 포함되지 않는다.

---

## 의존성 설치

```bash
pip install requests pandas openpyxl beautifulsoup4
```

---

## 파일 관계도

```
aladin_search.py          ← v1.00 (API 검색만, 목차 없음)
aladin_search_1.02.py     ← v1.02 (목차 스크래핑 프로토타입)
aladin_API_search_2.01.py ← v2.01 (현재 운영 버전)
```

> [!tip] 이전 버전 파일은 참고용이며, 실제 사용은 `aladin_API_search_2.01.py`만 사용한다.
