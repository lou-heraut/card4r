# Copyright 2026 Louis Héraut <louis.heraut@inrae.fr>
#
# INRAE, UR RiverLy, Villeurbanne, France
#
# This file is part of the card4r R package.
#
# card4r is free software: you can redistribute it and/or modify it under
# the terms of the license in the LICENSE file of this repository.

# Le pont vers Python, et la seule machinerie du paquet.
#
# `py_require()` DÉCLARE ce dont on a besoin ; reticulate (>= 1.41) le
# provisionne au premier appel avec uv, en téléchargeant au besoin
# l'interpréteur lui-même. L'utilisateur n'installe donc pas Python à la
# main. Mesuré le 2026-08-05 sur une machine sans Python déclaré ni uv :
# provisionnement complet et import réussi.
#
# Les deux paquets sont épinglés à un TAG, jamais à `main` : une version
# de card4r doit toujours appeler le même code, sinon un résultat n'est
# pas rejouable. Monter ces refs est un geste explicite, qui s'accompagne
# d'une version de card4r.
CARD_REF <- "v0.4.0"
STASE_REF <- "v0.6.1"

.card <- NULL

.onLoad <- function(libname, pkgname) {
  # Un utilisateur qui a désigné son propre interpréteur sait ce qu'il
  # fait : on ne déclare rien, sinon reticulate avertit à chaque appel que
  # les exigences ne sont pas satisfaites dans SON environnement. C'est
  # aussi le chemin hors ligne, et celui du développement de card.
  if (!nzchar(Sys.getenv("RETICULATE_PYTHON"))) {
    reticulate::py_require(c(
      sprintf("stase @ git+https://github.com/lou-heraut/stase.git@%s", STASE_REF),
      sprintf("card-stase @ git+https://github.com/lou-heraut/card.git@%s", CARD_REF)
    ))
  }
  # `delay_load` : rien ne part sur le réseau tant qu'aucune fonction du
  # paquet n'est appelée. `library(card4r)` reste donc instantané, et
  # `R CMD check` passe sur une machine sans Python.
  .card <<- reticulate::import("card", delay_load = TRUE, convert = TRUE)
}

#' L'environnement Python utilisé par card4r
#'
#' Diagnostic : dit quel interpréteur a été retenu et quelles versions de
#' `card` et `stase` répondent, avec leurs commits exacts.
#'
#' @return Une liste, invisible, des versions et commits publiés par
#'   `card.provenance()`. Affiche un résumé lisible.
#' @export
card_config <- function() {
  cfg <- reticulate::py_config()
  prov <- .card$provenance()
  cat("python       :", cfg$python, "\n")
  cat("card         :", prov$card_version, "\n")
  cat("card commit  :", prov$card_commit %||% "(copie modifi\u00e9e)", "\n")
  cat("stase        :", prov$stase_version, "\n")
  cat("stase commit :", prov$stase_commit %||% "(copie modifi\u00e9e)", "\n")
  invisible(prov)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
