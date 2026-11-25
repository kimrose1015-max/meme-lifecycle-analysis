rm(list=ls())
library(dplyr)

# 1. 공주의 경로 설정 (슬래시 주의!)
folder_path <- "C:/Users/김윤지/OneDrive/바탕 화면/데프기실_csv"
csv_files <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE)

# 2. 결과 저장용 테이블
meme_result <- data.frame(
  파일명 = character(),
  조건_충족_일수 = integer(),
  밈_여부 = character(),
  stringsAsFactors = FALSE
)

# 3. CSV 하나씩 확인
for (file in csv_files) {
  try({
    df <- read.csv(file, skip = 1, header = FALSE, fileEncoding = "UTF-8-BOM")
    colnames(df) <- c("날짜", "검색량")
    df$검색량 <- as.numeric(df$검색량)
    
    valid_days <- sum(df$검색량 >= 15, na.rm = TRUE)
    is_meme <- ifelse(valid_days >= 1, "밈", "아님")
    
    meme_result <- rbind(meme_result, data.frame(
      파일명 = basename(file),
      조건_충족_일수 = valid_days,
      밈_여부 = is_meme,
      stringsAsFactors = FALSE
    ))
  }, silent = TRUE)
}

# 4. 결과 확인
print(meme_result)

# 5. 결과 저장 (선택)
# write.csv(meme_result, "C:/Users/김윤지/OneDrive/바탕 화면/밈_판별_결과.csv", row.names = FALSE)
