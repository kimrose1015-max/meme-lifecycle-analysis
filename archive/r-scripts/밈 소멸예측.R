#밈 소멸일 예측
library(dplyr)
library(lubridate)

# 경로
csv_path <- "C:/Users/김윤지/OneDrive/바탕 화면/데프기실/밈_웹_주기.csv"
lifecycle_df <- read.csv(csv_path, fileEncoding = "UTF-8-BOM")

# 날짜 변환
lifecycle_df$start <- parse_date_time(lifecycle_df$start, orders = "b-y")
lifecycle_df$end <- parse_date_time(lifecycle_df$end, orders = "b-y")

# 생존개월수 계산
lifecycle_df <- lifecycle_df %>%
  filter(!is.na(start), !is.na(end)) %>%
  mutate(생존개월수 = as.numeric(difftime(end, start, units = "days")) %/% 30)

# 4️⃣ 검색량 벡터 추출 함수
extract_vec <- function(file_path, n = 30) {
  df <- read.csv(file_path, skip = 1, header = FALSE, fileEncoding = "UTF-8-BOM")
  colnames(df) <- c("날짜", "검색량")
  df$검색량 <- as.numeric(gsub("[^0-9.]", "", df$검색량))
  df <- df %>% filter(!is.na(검색량))
  vec <- df$검색량
  if (length(vec) >= n) {
    return(vec[1:n])
  } else {
    return(c(vec, rep(0, n - length(vec))))
  }
}

# 5️⃣ 훈련용 데이터 구성
feature_list <- list()
label_list <- c()

for (i in 1:nrow(lifecycle_df)) {
  fname <- lifecycle_df$파일명[i]
  path <- file.path(data_dir, fname)
  
  if (!file.exists(path) || is.na(lifecycle_df$생존개월수[i])) next
  
  features <- extract_vec(path)
  feature_list[[length(feature_list)+1]] <- features
  label_list <- c(label_list, lifecycle_df$생존개월수[i])
}

# 6️⃣ 모델 훈련
feature_matrix <- do.call(rbind, feature_list)
train_df <- data.frame(생존개월수 = label_list, feature_matrix)
colnames(train_df)[-1] <- paste0("V", 1:(ncol(train_df)-1))

set.seed(123)
model <- randomForest(생존개월수 ~ ., data = train_df, ntree = 200)
print(model)

# 7️⃣ 모델 저장 (선택)
saveRDS(model, "C:/Users/김윤지/OneDrive/바탕 화면/웹/생존개월수_회귀모델.rds")
