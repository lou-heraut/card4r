# Copyright 2026 Louis Héraut <louis.heraut@inrae.fr>
#
# INRAE, UR RiverLy, Villeurbanne, France
#
# This file is part of the card4r R package.
#
# card4r is free software: you can redistribute it and/or modify it under
# the terms of the license in the LICENSE file of this repository.

# Ce qui traverse le pont, c'est de la DONNÉE, jamais du code.
#
# Un data.frame entre, des data.frames et leurs métadonnées sortent. Le
# paquet ne republie pas les fonctions hydro de card, et n'offre aucun
# moyen d'écrire une fiche en R : ce jour-là il faudrait faire traverser
# des fonctions R au pont, et le coût passerait d'un week-end à un an.
# Une fiche s'écrit en YAML, dans le corpus, où qu'on la lise.
#
# Ne restent donc à traiter que les dates, seul endroit où R et pandas ne
# se comprennent pas d'eux-mêmes.

#' Calculer des variables hydroclimatiques
#'
#' @param data Un data.frame : une colonne de dates, une colonne
#'   d'identifiant de série, et les colonnes numériques que les fiches
#'   demandent (`Q` pour le débit, `T` pour la température...).
#' @param cards Les fiches à calculer, par leur identifiant.
#' @param date_col Nom de la colonne de dates.
#' @param ... Passé tel quel à `card.extract` en Python : `suffix`,
#'   `sampling_period`, `rename`, `metadata_only`...
#'
#' @return Une liste : `data`, une liste nommée de data.frames (un par
#'   fiche), et `meta`, un data.frame d'une ligne par variable produite.
#'   `meta` porte la définition employée (`version`, `swhid`) et le
#'   logiciel qui a calculé (`card_commit`, `stase_commit`).
#' @export
card_extract <- function(data, cards = c("QA", "QJXA"), date_col = "date", ...) {
  stopifnot(is.data.frame(data))
  py <- .card$extract(.to_py(data, date_col), cards = as.list(cards), ...)
  out <- .from_py(py)
  # L'objet Python est conservé pour `card_trend()`, qui doit recevoir la
  # table telle que card l'a produite (dtypes et métadonnées comprises) et
  # non sa traduction en R.
  attr(out, "py") <- py
  out
}

#' Tester la stationnarité d'une extraction
#'
#' @param x Le résultat de [card_extract()], dans la même session R.
#' @param ... Passé tel quel à `card.trend` : `level`, `mk`, `period`...
#'
#' @return Même forme que [card_extract()] : `data` et `meta`. La colonne
#'   `h` dit si la tendance est significative, `a` est la pente de Sen.
#' @export
card_trend <- function(x, ...) {
  py <- attr(x, "py")
  if (is.null(py)) {
    stop("card_trend() attend le retour de card_extract(), produit dans ",
         "la meme session R.", call. = FALSE)
  }
  .from_py(.card$trend(py, ...))
}

#' Lister les fiches du corpus
#'
#' @param ... Filtres de facette, en français ou en anglais :
#'   `phenomenon = "basses eaux"`, `output = "serie"`, `operator = "delta"`.
#' @return Un data.frame, une ligne par variable.
#' @export
card_list <- function(...) {
  .from_py(.card$list_cards(...))
}

#' Afficher une fiche
#'
#' @param name Identifiant de la fiche, par exemple `"VCN10"`.
#' @param lang `"fr"` ou `"en"`.
#' @return La figure, invisible, telle qu'elle est affichée.
#' @export
card_info <- function(name, lang = "fr") {
  figure <- .card$figure(name, lang = lang)
  cat(figure, "\n")
  invisible(figure)
}


# ── Dates : le seul endroit où R et pandas ne se comprennent pas ───────

.to_py <- function(data, date_col) {
  # Une colonne `Date` traverse le pont en TEXTE (dtype `object`), que
  # card convertit en le signalant ; un avertissement qu'on ne peut pas
  # éviter finit par être ignoré. Une `POSIXct` en UTC, elle, arrive
  # nativement en `datetime64[ns]` à la bonne valeur (mesuré). D'où cette
  # unique ligne, plutôt qu'une conversion côté pandas.
  if (date_col %in% names(data) && !inherits(data[[date_col]], "POSIXct")) {
    data[[date_col]] <- as.POSIXct(as.Date(data[[date_col]]), tz = "UTC")
  }
  reticulate::r_to_py(data)
}

.from_py <- function(py) {
  out <- reticulate::py_to_r(py)
  .rendre_les_dates(out)
}

.rendre_les_dates <- function(x) {
  if (is.data.frame(x)) {
    for (col in names(x)) {
      x[[col]] <- .en_date(x[[col]])
    }
    return(x)
  }
  if (is.list(x)) {
    return(lapply(x, .rendre_les_dates))
  }
  x
}

.en_date <- function(v) {
  # pandas rend des horodatages SANS fuseau ; reticulate les interprète
  # dans le fuseau local, ce qui décale un minuit du 1er janvier au 31
  # décembre de l'année précédente. On relit donc en UTC, et on rend une
  # Date quand la partie horaire est nulle, ce qui est le cas des axes de
  # temps et des fiches qui rendent une date.
  if (!inherits(v, "POSIXct")) {
    return(v)
  }
  heures <- format(v, "%H%M%S", tz = "UTC")
  if (all(is.na(heures) | heures == "000000")) {
    return(as.Date(format(v, "%Y-%m-%d", tz = "UTC")))
  }
  v
}
