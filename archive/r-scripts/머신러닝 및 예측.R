library(dplyr)

folder_path <- "C:/Users/김윤지/OneDrive/바탕 화면/데프기실_csv"
csv_files <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE)
csv_files <- csv_files[!grepl("^~\\$", basename(csv_files))]

meme_result <- data.frame(
  파일명 = character(),
  시작일 = character(),
  소멸일 = character(),
  상태 = character(),
  stringsAsFactors = FALSE
)

# 밈 구간 탐색 함수 (공주가 이미 만든 거 여기에 있다고 가정)
# find_meme_periods <- function(df) { ... }

for (file in csv_files) {
  result <- tryCatch({
    # ✅ 인코딩 백업 전략
    df <- tryCatch(
      read.csv(file, skip = 1, header = FALSE, fileEncoding = "UTF-8-BOM"),
      error = function(e) {
        read.csv(file, skip = 1, header = FALSE, fileEncoding = "euc-kr")
      }
    )
    
    colnames(df) <- c("날짜", "검색량")
    df$날짜 <- as.character(df$날짜)
    
    # ✅ 데이터 정리
    df$검색량 <- gsub(",", "", df$검색량)
    df$검색량 <- gsub("[^0-9\\.]", "", df$검색량)
    df$검색량 <- as.numeric(df$검색량)
    df <- df %>% filter(!is.na(검색량))
    
    periods <- find_meme_periods(df)
    
    if (length(periods) > 0) {
      rows <- lapply(periods, function(p) {
        data.frame(
          파일명 = basename(file),
          시작일 = df$날짜[p[1]],
          소멸일 = ifelse(is.na(p[2]), NA, df$날짜[p[2]]),
          상태 = "정상",
          stringsAsFactors = FALSE
        )
      })
      do.call(rbind, rows)
    } else {
      data.frame(
        파일명 = basename(file),
        시작일 = NA,
        소멸일 = NA,
        상태 = "조건 불충족",
        stringsAsFactors = FALSE
      )
    }
  }, error = function(e) {
    data.frame(
      파일명 = basename(file),
      시작일 = NA,
      소멸일 = NA,
      상태 = paste("에러:", substr(e$message, 1, 50)),
      stringsAsFactors = FALSE
    )
  })
  
  meme_result <- rbind(meme_result, result)
}

View(meme_result)       # 표 형태로 열어보기
print(meme_result)
