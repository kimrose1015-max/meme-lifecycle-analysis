# 데이터 안내

## 폴더별 역할

| 위치 | 내용 |
| --- | --- |
| `data/raw/web-original` | 원본 폴더에 보존된 웹 시계열 98개 |
| `data/subsets/web-long` | 웹 장기 표본 54개 |
| `data/raw/web-analysis` | 원본 `웹 전체.zip`에서 추출한 월별 웹 검색량 78개 |
| `data/processed` | 웹·유튜브의 시작/소멸/기간/유형 및 평균 검색량 |
| `data/subsets/web-short` | 웹 단기 44개 |
| `data/subsets/youtube-short` | 유튜브 단기 51개 |
| `data/subsets/common-web`, `common-youtube` | 공통 단기 표본 각 36개 |
| `data/subsets/web-only-short` | 웹에서만 단기로 분류된 표본 8개 |
| `data/subsets/youtube-only-short` | 유튜브에서만 단기로 분류된 표본 15개 |
| `results/original` | 예측결과 78행, 실제결과 100행, 병합 77행, 평균 검색량 |
| `archive/zips` | 당시 데이터 묶음 원본, 압축 해제본과 중복될 수 있음 |

`web-analysis`의 “raw”는 프로젝트가 제공한 검색량 CSV라는 뜻입니다. Google에서 다시 수집하거나 원시 수집 설정을 복원한 자료는 아닙니다. 원본 폴더의 웹 전체(78개), 웹 전체 원본(98개), 단기/장기, ZIP은 서로 다른 표본 묶음이므로 한 데이터셋으로 합치지 않습니다. 전체 100개에 대한 웹·유튜브 원시 시계열이 모두 보존되어 있다고 주장하지 않습니다.

## CSV 구조

### Google Trends 시계열

앞 2줄은 카테고리·빈 줄이며 3번째 줄이 헤더입니다. 열은 `월`과 `검색어: (대한민국)` 형태입니다. 검색량은 정규화된 관심도이며 절대 검색 횟수가 아닙니다. `<1`은 실행 스크립트에서 0으로 처리합니다.

### 주기 및 실제결과

- `file`: 검색어 CSV 파일명
- `start`, `end`: 추출된 시작·소멸 시점
- `end_filled`: 소멸 결측값을 당시 분석일로 채운 값
- `duration_months`: 월 단위 기간
- `type`: 단기, 장기 또는 미분류

### 예측 및 병합

- `예측결과.csv`: `file`, `type`
- `병합.csv`: 인덱스, `file`, `predicted`, `file_clean`, `actual`
- `웹_단기_평균검색량.csv`: `week`, `avg_value`, `type`

파일명과 CSV 내부 파일명에는 NFC/NFD 한글 표기가 섞여 있습니다. `audit_results.py`에서는 Unicode NFC로 정규화해 비교합니다. 원본 CSV 내용은 그대로 보존합니다. `week` 열 이름은 원본 표기를 유지했으며 원시 데이터의 월 간격과 혼동하지 않아야 합니다.

## 출처 추적

`provenance.csv`는 원본 상대경로, 저장소 경로, SHA-256을 기록합니다. 원본 폴더는 수정하지 않습니다. `.DS_Store` 등 운영체제 메타데이터는 업로드 대상에서 제외합니다.
