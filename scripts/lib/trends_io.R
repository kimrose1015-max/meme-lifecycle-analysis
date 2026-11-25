# Shared input handling for the additional R scripts. Run from the repo root.
parse_lifecycle_date <- function(x) {
  x <- trimws(as.character(x))
  result <- as.Date(rep(NA_character_, length(x)))
  monthly <- !is.na(x) & grepl("^[0-9]{4}-[0-9]{2}$", x)
  daily <- !is.na(x) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)
  result[monthly] <- as.Date(paste0(x[monthly], "-01"), format = "%Y-%m-%d")
  result[daily] <- as.Date(x[daily], format = "%Y-%m-%d")
  # Original b-y input: English month names, independent of the OS locale.
  legacy <- which(!is.na(x) & grepl("^[A-Za-z]{3}-[0-9]{2}$", x))
  if (length(legacy)) {
    month <- match(tolower(substr(x[legacy], 1, 3)), tolower(month.abb))
    year <- 2000L + as.integer(substr(x[legacy], 5, 6))
    result[legacy] <- as.Date(sprintf("%04d-%02d-01", year, month), format = "%Y-%m-%d")
  }
  result
}

read_trends_series <- function(path) {
  for (encoding in c("UTF-8", "CP949")) {
    lines <- tryCatch(suppressWarnings(readLines(path, encoding = encoding, warn = FALSE)),
                      error = function(e) NULL)
    if (is.null(lines)) next
    lines <- iconv(lines, from = encoding, to = "UTF-8")
    if (anyNA(lines)) next
    # Detect the first date row; metadata/header lengths differ across exports.
    first <- which(grepl('^\\s*"?[0-9]{4}-[0-9]{2}(-[0-9]{2})?"?,', lines))[1]
    if (is.na(first)) next
    df <- tryCatch(read.csv(text = paste(lines[first:length(lines)], collapse = "\n"),
                            header = FALSE, colClasses = "character", check.names = FALSE),
                   error = function(e) NULL)
    if (is.null(df) || ncol(df) != 2L) next
    names(df) <- c("date", "value")
    df$date <- parse_lifecycle_date(df$date)
    raw <- trimws(gsub(",", "", df$value, fixed = TRUE))
    raw[raw == "<1"] <- "0"
    df$value <- suppressWarnings(as.numeric(raw))
    if (anyNA(df$date) || anyNA(df$value) || any(!is.finite(df$value)) ||
        any(df$value < 0 | df$value > 100)) {
      stop("Invalid date or Google Trends interest value: ", basename(path))
    }
    if (is.unsorted(df$date, strictly = TRUE)) stop("Dates must be unique and increasing: ", basename(path))
    return(df)
  }
  stop("No readable two-column date/value series: ", basename(path))
}

list_trends_files <- function(input_dir) {
  if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
  files <- sort(list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE))
  files <- files[!startsWith(basename(files), "~$")]
  if (!length(files)) stop("No input CSV files: ", input_dir)
  files
}

extract_search_vector <- function(path, n = 30L) {
  values <- read_trends_series(path)$value
  # Preserve the original file-first window and zero-padding policy.
  c(head(values, n), rep(0, max(0L, n - length(values))))
}

write_result_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.csv(data, path, row.names = FALSE, fileEncoding = "UTF-8", na = "")
}
