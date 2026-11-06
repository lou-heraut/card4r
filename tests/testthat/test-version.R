# Le numéro de version est recopié dans CITATION.cff et dans
# codemeta.json : ce sont les seuls endroits qui puissent se désaccorder
# du DESCRIPTION, donc les seuls à surveiller. Autant que ça casse ici
# plutôt que dans une bibliographie.
#
# Même garde que `tests/test_citation.py` dans card et dans stase.

test_that("CITATION.cff annonce la version du paquet", {
  racine <- testthat::test_path("..", "..")
  desc <- file.path(racine, "DESCRIPTION")
  cff <- file.path(racine, "CITATION.cff")
  skip_if_not(file.exists(desc) && file.exists(cff),
              "sources absentes (paquet installe)")

  paquet <- unname(read.dcf(desc, fields = "Version")[1, 1])
  lignes <- readLines(cff, warn = FALSE)
  citation <- sub('^version:\\s*"?([^"]+)"?\\s*$', "\\1",
                  grep("^version:", lignes, value = TRUE)[1])

  expect_equal(citation, paquet,
               info = "CITATION.cff et DESCRIPTION doivent porter le meme numero")
})

test_that("codemeta.json annonce la version du paquet", {
  racine <- testthat::test_path("..", "..")
  desc <- file.path(racine, "DESCRIPTION")
  meta <- file.path(racine, "codemeta.json")
  skip_if_not(file.exists(desc) && file.exists(meta),
              "sources absentes (paquet installe)")

  paquet <- unname(read.dcf(desc, fields = "Version")[1, 1])
  lignes <- readLines(meta, warn = FALSE, encoding = "UTF-8")
  champ <- grep('^\\s*"version"\\s*:', lignes, value = TRUE)[1]
  codemeta <- sub('^\\s*"version"\\s*:\\s*"([^"]+)".*$', "\\1", champ)

  expect_equal(codemeta, paquet,
               info = "codemeta.json et DESCRIPTION doivent porter le meme numero")
})
