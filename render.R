options(
  repos = c(
    getOption("repos"),
    INLA = "https://inla.r-inla-download.org/R/stable"
  )
)
current <- getwd()
rmarkdown::render("index.Rmd")
unlink("docs", recursive = TRUE)
packages <- readRDS("src/contrib/PACKAGES.rds")
to.do <- as.vector(packages[, c("Suggests", "LinkingTo", "Depends", "Imports")])
to.do <- paste(na.omit(to.do), collapse = ", ")
to.do <- gsub("\\n", " ", to.do)
to.do <- gsub(" \\(.*?\\)", "", to.do)
dependencies <- unique(strsplit(to.do, ", ")[[1]])
dependencies <- dependencies[dependencies != "R"]
junk <- sapply(
  dependencies,
  function(x){
    if (length(find.package(x, quiet = TRUE)) == 0) {
      install.packages(x)
    }
  }
)
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
    devtools::install_local(path = ".", upgrade_dependencies = FALSE)
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
