suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(lubridate)
})

# Run from the repository root. Counts retain the original observation-based rules.
args <- commandArgs(trailingOnly = TRUE)
input_dir <- if (length(args) >= 1) args[1] else "data/raw/web-analysis"
output_csv <- if (length(args) >= 2) args[2] else "results/generated/predictions.csv"
drop_threshold <- if (length(args) >= 3) as.numeric(args[3]) else 0.50
if (is.na(drop_threshold) || drop_threshold < 0 || drop_threshold > 1) {
  stop("Drop threshold must be between 0 and 1.")
}
files <- sort(list.files(input_dir, pattern = "\\.csv$", full.names = TRUE))
if (!length(files)) stop("No input CSV files: ", input_dir)

classify_meme <- function(filepath) {
  result <- function(type) tibble(file = basename(filepath), type = type)
  df <- read_csv(filepath, skip = 3, col_names = c("date", "value"),
                 col_types = cols(.default = col_character()), show_col_types = FALSE)
  df <- df %>% mutate(
    value = suppressWarnings(as.numeric(ifelse(str_detect(value, "<1"), "0", value))),
    date = ym(date, quiet = TRUE)
  ) %>% filter(!is.na(value))
  if (nrow(df) < 8 || max(df$value) <= 0) return(result("데이터 부족"))
  max_val <- max(df$value)
  runs <- rle(df$value >= 0.15 * max_val)
  run_index <- which(runs$values & runs$lengths >= 4)[1]
  if (is.na(run_index)) return(result("15% 이상 지속 없음"))
  previous_length <- if (run_index == 1) 0 else sum(runs$lengths[seq_len(run_index - 1)])
  valid <- df[(previous_length + 1):nrow(df), ]
  below <- which(valid$value < 0.15 * max_val)
  if (length(below)) valid <- valid[seq_len(below[1] - 1), ]
  if (!any(valid$value >= 0.80 * max_val)) return(result("80% 피크 없음"))
  peak <- which.max(valid$value)
  if (peak >= nrow(valid)) return(result("하락 판단 불가"))
  after <- valid$value[(peak + 1):min(peak + 4, nrow(valid))]
  if (length(after) < 2) return(result("하락 판단 불가"))
  drop <- (valid$value[peak] - mean(after)) / valid$value[peak]
  result(ifelse(drop >= drop_threshold, "단기", "장기"))
}

results <- bind_rows(lapply(files, classify_meme))
dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
write_csv(results, output_csv)
print(count(results, type))
cat("Input files:", length(files), "| Drop threshold:", drop_threshold, "\n")
cat("Saved:", output_csv, "\n")
