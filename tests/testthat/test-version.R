# Le numéro de version est recopié dans CITATION.cff : c'est le seul
# endroit qui puisse se désaccorder du DESCRIPTION, donc le seul à
# surveiller. Autant que ça casse ici plutôt que dans une bibliographie.
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
