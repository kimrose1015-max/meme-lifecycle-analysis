# Experimental total-lifespan regression; distinct from binary classification.
source("scripts/lib/trends_io.R", encoding = "UTF-8")
for (package in c("randomForest", "stringi")) {
  if (!requireNamespace(package, quietly = TRUE)) stop("Install required package: ", package)
}
args <- commandArgs(trailingOnly = TRUE)
data_dir <- if (length(args) >= 1L) args[1] else "data/raw/web-analysis"
lifecycle_csv <- if (length(args) >= 2L) args[2] else "data/processed/밈_웹_주기.csv"
output_dir <- if (length(args) >= 3L) args[3] else "results/generated/survival-regression"

files <- list_trends_files(data_dir)
keys <- stringi::stri_trans_nfc(basename(files))
if (anyDuplicated(keys)) stop("Ambiguous filenames after Unicode normalization.")
lifecycle <- read.csv(lifecycle_csv, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
if (!all(c("start", "end") %in% names(lifecycle))) stop("Lifecycle CSV needs start and end columns.")
file_column <- if ("file" %in% names(lifecycle)) "file" else "파일명"
if (!file_column %in% names(lifecycle)) stop("Lifecycle CSV needs file or 파일명 column.")
labels <- as.character(lifecycle[[file_column]])
if (anyDuplicated(stringi::stri_trans_nfc(labels))) stop("Duplicate lifecycle filenames are not supported.")
starts <- parse_lifecycle_date(lifecycle$start)
ends <- parse_lifecycle_date(lifecycle$end)
features <- list()
manifest <- list()
skipped <- list()
for (i in seq_len(nrow(lifecycle))) {
  reason <- NULL
  vector <- NULL
  months <- NA_real_
  index <- match(stringi::stri_trans_nfc(labels[i]), keys)
  if (is.na(starts[i]) || is.na(ends[i])) {
    reason <- "missing_or_invalid_start_end"
  } else if (ends[i] < starts[i]) {
    reason <- "end_before_start"
  } else if (is.na(index)) {
    reason <- "search_csv_not_found"
  } else {
    months <- as.numeric(difftime(ends[i], starts[i], units = "days")) %/% 30
    vector <- tryCatch(extract_search_vector(files[index], 30L), error = function(e) {
      reason <<- conditionMessage(e)
      NULL
    })
  }
  if (!is.null(reason)) {
    skipped[[length(skipped) + 1L]] <- data.frame(file = labels[i], reason = reason)
    next
  }
  features[[length(features) + 1L]] <- vector
  manifest[[length(manifest) + 1L]] <- data.frame(
    file = labels[i], source_file = basename(files[index]),
    start = as.character(starts[i]), end = as.character(ends[i]), survival_months = months)
}
skipped_df <- if (length(skipped)) do.call(rbind, skipped) else data.frame(file = character(), reason = character())
write_result_csv(skipped_df, file.path(output_dir, "skipped.csv"))
if (length(features) < 5L) stop("Fewer than five usable training rows; inspect skipped.csv.")
training_manifest <- do.call(rbind, manifest)
if (length(unique(training_manifest$survival_months)) < 2L) stop("Training targets have no variation.")
feature_matrix <- do.call(rbind, features)
colnames(feature_matrix) <- paste0("V", seq_len(ncol(feature_matrix)))
train_df <- data.frame(survival_months = training_manifest$survival_months, feature_matrix)
set.seed(123)
model <- randomForest::randomForest(survival_months ~ ., data = train_df, ntree = 200)
saveRDS(model, file.path(output_dir, "survival_regression.rds"))
write_result_csv(cbind(training_manifest, feature_matrix), file.path(output_dir, "training-data.csv"))
print(model)
cat("Training rows:", nrow(train_df), "| Skipped rows:", nrow(skipped_df), "\n")
cat("Features: first 30 observations in each CSV; target: floor(days / 30).\n")
cat("OOB statistics describe this fit; no independent test-set performance is established.\n")
cat("Saved:", output_dir, "\n")
