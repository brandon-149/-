CLAUDE.MD - 국립중앙도서관 API 학습교재 데이터 수집 프로젝트
📋 프로젝트 개요
국립중앙도서관 API를 활용하여 국내 출판된 초중고 학습 교재 정보를 수집하고 Excel 파일로 저장하는 프로젝트입니다.
🎯 목적
국립중앙도서관 API를 통해 학습 교재의 서지 정보를 자동으로 수집하여 Excel 형식으로 데이터베이스를 구축합니다.
📊 수집 데이터 항목
항목설명TITLE표제 (책 제목)AUTHOR저자EA_ISBNISBNPUBLISHER발행처PRE_PRICE예정가격PAGE페이지 수PUBLISH_PREDATE출판 예정일TITLE_URL표제 이미지 URLBOOK_TB_CNT_URL목차 정보PUBLISHER_URL출판사 홈페이지INPUT_DATE등록 날짜
🛠️ 개발 환경

IDE: Visual Studio Code
언어: Python 3.x
출력 형식: Excel (.xlsx)

📦 필요한 라이브러리
pythonpip install requests
pip install openpyxl
pip install pandas
```

## 🔑 API 정보
- **API 제공**: 국립중앙도서관
- **API 키**: ad6e03af9e224764a3cf6566d12048e22d6abae0081c47226266faae0d60c52e
- **API 문서**: 국립중앙도서관 서지정보 유통 지원 시스템

## 📂 프로젝트 구조
```
project/
│
├── main.py                 # 메인 실행 파일
├── config.py              # API 키 및 설정
├── api_handler.py         # API 요청 처리
├── data_processor.py      # 데이터 가공
├── excel_writer.py        # Excel 파일 생성
├── requirements.txt       # 필요 라이브러리 목록
└── output/               # 출력 파일 저장 폴더
    └── textbooks_YYYYMMDD.xlsx
🚀 사용 방법

API 키 발급 받기
config.py에 API 키 입력
검색 조건 설정 (학년, 과목 등)
python main.py 실행
output/ 폴더에서 결과 확인

📝 주요 기능

 국립중앙도서관 API 연동
 학습 교재 검색 필터링
 페이지네이션 처리
 데이터 정제 및 가공
 Excel 파일 생성 및 저장
 에러 핸들링 및 로깅

⚠️ 주의사항

API 호출 제한을 확인하고 준수해야 합니다
API 키는 반드시 비공개로 관리해야 합니다
대량 데이터 수집 시 시간이 소요될 수 있습니다

📌 TODO

 API 인증 구현
 데이터 검색 로직 작성
 Excel 출력 포맷 설계
 예외 처리 추가
 진행 상황 표시 기능

💡 참고 자료

국립중앙도서관 Open API 가이드
openpyxl 공식 문서
pandas 공식 문서

📄 라이선스
이 프로젝트는 교육 목적으로 작성되었습니다.

작성일: 2026-02-12
버전: 1.0
