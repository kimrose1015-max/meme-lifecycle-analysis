# Screening only: this does not extract lifecycle start/end dates.
source("scripts/lib/trends_io.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
input_dir <- if (length(args) >= 1L) args[1] else "data/raw/web-analysis"
output_csv <- if (length(args) >= 2L) args[2] else "results/generated/meme-screening.csv"
files <- list_trends_files(input_dir)

rows <- lapply(files, function(path) {
  tryCatch({
    df <- read_trends_series(path)
    valid_count <- sum(df$value >= 15)
    data.frame(file = basename(path), qualifying_observations = valid_count,
               is_meme = valid_count >= 1L, status = "ok", stringsAsFactors = FALSE)
  }, error = function(e) {
    data.frame(file = basename(path), qualifying_observations = NA_integer_,
               is_meme = NA, status = conditionMessage(e), stringsAsFactors = FALSE)
  })
})
results <- do.call(rbind, rows)
write_result_csv(results, output_csv)
print(table(results$is_meme, useNA = "ifany"))
cat("Input files:", nrow(results), "| Errors:", sum(results$status != "ok"), "\n")
cat("Saved:", output_csv, "\n")
