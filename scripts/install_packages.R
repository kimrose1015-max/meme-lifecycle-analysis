packages <- c("readr", "dplyr", "stringr", "lubridate", "ggplot2", "randomForest", "stringi")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
