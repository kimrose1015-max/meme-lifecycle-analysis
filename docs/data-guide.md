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

## 추가 R 코드의 입력·출력

`screen_memes.R`는 기본적으로 `data/raw/web-analysis`를 읽고 `file`, `qualifying_observations`, `is_meme`, `status`를 출력합니다. 관측치 단위는 입력 날짜 간격을 따릅니다.

`train_survival_regression.R`는 같은 폴더와 `data/processed/밈_웹_주기.csv`의 `file`, `start`, `end`를 연결합니다. Unicode NFC 정규화 후 파일명이 일치하는 자료만 사용합니다. 생성되는 `training-data.csv`는 원본 파일명·대응 파일명·시작일·소멸일·목표 생존기간·검색량 특성을 담고, `skipped.csv`는 제외 사유를 담습니다. 시작/소멸 결측을 분석일로 채우지 않습니다.

추가 원본 R 파일 3개의 경로와 SHA-256은 `r-scripts-provenance.csv`에 따로 기록했습니다. 모델과 결과는 `results/generated/`에 생성됩니다. [실행 방법과 해석](additional-r-analysis.md)을 참고하세요.
