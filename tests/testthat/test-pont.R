# Le pont, éprouvé là où R et Python ne se comprennent pas d'eux-mêmes.
#
# Ces tests demandent un Python provisionné, donc du réseau au premier
# appel : ils se sautent proprement quand il n'y en a pas, plutôt que de
# faire échouer un `R CMD check` hors ligne.

serie_essai <- function() {
  set.seed(42)
  dates <- seq(as.Date("1970-01-01"), as.Date("2020-12-31"), by = "day")
  saison <- 1 + 0.6 * cos(2 * pi * (as.integer(format(dates, "%j")) - 30) / 365)
  data.frame(date = dates,
             Q = rgamma(length(dates), 2, scale = 5) * saison *
                 seq(1, 0.75, length.out = length(dates)),
             id = "ma_station")
}

skip_sans_python <- function() {
  skip_on_cran()
  ok <- tryCatch({
    card_list()
    TRUE
  }, error = function(e) FALSE)
  skip_if_not(ok, "aucun Python utilisable")
}

test_that("une extraction rend des data.frames et leurs metadonnees", {
  skip_sans_python()
  res <- card_extract(serie_essai(), cards = c("QA", "VCN10"))

  expect_named(res, c("data", "meta"))
  expect_s3_class(res$data$QA, "data.frame")
  expect_true(all(c("QA", "VCN10") %in% res$meta$variable_en))
})

test_that("la colonne de temps revient en Date, sans decalage de fuseau", {
  # pandas rend des horodatages sans fuseau ; interpretes en heure locale,
  # un minuit du 1er janvier devient le 31 decembre precedent.
  skip_sans_python()
  res <- card_extract(serie_essai(), cards = "QA")

  expect_s3_class(res$data$QA$date, "Date")
  expect_equal(format(res$data$QA$date[2], "%m-%d"), "09-01")
})

test_that("un resultat dit avec quel logiciel il a ete calcule", {
  skip_sans_python()
  meta <- card_extract(serie_essai(), cards = "QA")$meta

  expect_true(all(c("card_version", "card_commit",
                    "stase_version", "stase_commit") %in% names(meta)))
  expect_match(meta$card_version[1], "^[0-9]+[.][0-9]+")
})

test_that("la tendance recoit la table de card, pas sa traduction", {
  skip_sans_python()
  res <- card_extract(serie_essai(), cards = "VCN10")
  # stase avertit ici que `relative` vaut une seule valeur pour toutes les
  # variables ; c'est le test precedent qui couvre ce trajet.
  tr <- suppressWarnings(card_trend(res))

  expect_true(all(c("h", "p", "a") %in% names(tr$data$VCN10)))
  expect_type(tr$data$VCN10$h, "logical")
})

test_that("un avertissement de Python devient un warning R", {
  # Imprime par Python sur stderr, un avertissement echappe a R : ni
  # suppressWarnings(), ni options(warn = 2), ni tryCatch n'ont prise
  # dessus. On verifie donc qu'il traverse en condition R, pas en texte.
  skip_sans_python()
  trouee <- serie_essai()[-(100:118), ]

  expect_warning(card_extract(trouee, cards = "QA"), "pas de temps manquants")

  attrape <- tryCatch(card_extract(trouee, cards = "QA"),
                      warning = function(w) conditionMessage(w))
  expect_match(attrape, "Grille day")

  # Deux fiches avertissent deux fois du meme trou : un seul warning sort.
  n <- 0L
  withCallingHandlers(
    card_extract(trouee, cards = c("QA", "VCN10")),
    warning = function(w) {
      n <<- n + 1L
      invokeRestart("muffleWarning")
    })
  expect_equal(n, 1L)

  # Et une serie complete n'avertit de rien : les filtres de Python sont
  # laisses intacts, donc ses DeprecationWarning restent tus.
  expect_warning(card_extract(serie_essai(), cards = "QA"), NA)
})

test_that("card_config dit quel code a repondu, et c'est celui qui est epingle", {
  # `CARD_REF` et `STASE_REF` decident quel code calcule. Rien ne verifiait
  # qu'un tag epingle correspond a ce qui repond vraiment, alors que c'est
  # la promesse centrale du paquet : deux personnes sur la meme version de
  # card4r executent le meme code.
  skip_sans_python()
  prov <- capture.output(config <- card_config())

  expect_true(all(c("card_version", "card_commit",
                    "stase_version", "stase_commit") %in% names(config)))
  expect_true(any(grepl("^python", prov)))

  # Hors environnement impose par l'utilisateur, ou tout est possible.
  skip_if(nzchar(Sys.getenv("RETICULATE_PYTHON")),
          "interpreteur impose : les refs epinglees ne s'appliquent pas")
  expect_equal(config$card_version, sub("^v", "", CARD_REF))
  expect_equal(config$stase_version, sub("^v", "", STASE_REF))
})

test_that("card_trend refuse un objet qui ne vient pas de card_extract", {
  expect_error(card_trend(list(data = NULL)), "card_extract")
})

test_that("les memes nombres que le paquet R historique", {
  # La bascule de CARD vers card4r ne doit rien changer aux valeurs.
  # Mesure du 2026-08-05 : ecart maximal 1,8e-15, soit la precision
  # machine, sur QA et VCN10.
  skip_sans_python()
  skip_if_not_installed("CARD")

  data <- serie_essai()
  py <- card_extract(data, cards = c("QA", "VCN10"))
  r <- CARD::CARD_extraction(data, CARD_name = c("QA", "VCN10"))

  for (v in c("QA", "VCN10")) {
    a <- py$data[[v]][[v]]
    b <- r$data[[v]][[v]]
    expect_equal(length(a), length(b))
    expect_equal(a, b, tolerance = 1e-12)
  }
})
