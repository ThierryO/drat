options(
  repos = c(
    getOption("repos"),
    INLA = "https://inla.r-inla-download.org/R/stable"
  )
)
current <- getwd()
unlink("docs", recursive = TRUE)
packages <- readRDS("src/contrib/PACKAGES.rds")
tarbals <- sprintf(
  "src/contrib/%s_%s.tar.gz", packages[, "Package"], packages[, "Version"]
)
junk <- lapply(tarbals, untar, exdir = tempdir())
devtools::install_github("hadley/pkgdown", upgrade_dependencies = FALSE)
junk <- sapply(
  packages[, "Package"],
  function(package) {
    source <- paste(tempdir(), package, sep = "/")
    setwd(source)
    target <- sprintf("docs/%s", package)
    devtools::install(upgrade_dependencies = FALSE, dependencies = TRUE)
    test <- try(pkgdown::build_site(preview = FALSE))
    if (inherits(test, "try-error")) {
      return(NULL)
    }
    website <- list.files("docs", recursive = TRUE, full.names = TRUE)
    targets <- gsub("docs/(.*)", sprintf("%s/%s/\\1", current, target), website)
    junk <- sapply(
      unique(dirname(targets)),
      function(x) {
        if (!dir.exists(x)) {
          dir.create(x, recursive = TRUE)
        }
      }
    )
    ok <- file.copy(website, targets)
    if (!all(ok)) {
      stop("Failed to copy some pkgdown files")
    }
  }
)
setwd(current)
rmarkdown::render("index.Rmd")
