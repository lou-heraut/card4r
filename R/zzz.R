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
CARD_REF <- "v0.9.0"
STASE_REF <- "v0.6.3"

.card <- NULL
.warnings <- NULL

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
  # `convert = FALSE` est ESSENTIEL ici : avec la conversion, reticulate
  # copie en R la liste de captures au moment où le bloc s'ouvre, donc
  # vide, et un appel qui avertit ne rend jamais rien.
  .warnings <<- reticulate::import("warnings", delay_load = TRUE,
                                   convert = FALSE)
}

# ── Avertissements : le second endroit où R et Python ne se parlent pas ─
#
# Un `warnings.warn()` Python n'est pas une valeur de retour : c'est un
# texte écrit sur stderr, que reticulate laisse simplement passer. Il
# arrive donc chez l'utilisateur avec le chemin du `.py` qui l'a émis, et
# surtout il échappe à R : ni `suppressWarnings()`, ni `options(warn = 2)`,
# ni `tryCatch` n'ont prise dessus. On l'intercepte pour le réémettre en
# `warning()` R, qui est ce qu'un appelant sait traiter.
#
# On ne touche PAS aux filtres de Python (pas de `simplefilter`) : ses
# défauts taisent déjà les `DeprecationWarning` de pandas et numpy, qui ne
# regardent pas l'utilisateur de card4r. Les forcer à remonter rendrait
# bavard un calcul qui ne l'était pas.
.avec_avertissements_r <- function(expr) {
  captures <- NULL
  valeur <- with(.warnings$catch_warnings(record = TRUE), as = w, {
    resultat <- force(expr)
    captures <- w
    resultat
  })
  for (message in .messages_python(captures)) {
    warning(message, call. = FALSE)
  }
  valeur
}

.messages_python <- function(captures) {
  n <- reticulate::py_len(captures)
  if (n == 0) {
    return(character())
  }
  # Python indexe à partir de 0. `unique()` parce qu'une extraction
  # multi-fiches répète le même avertissement une fois par fiche.
  unique(vapply(seq_len(n) - 1,
                function(i) reticulate::py_str(captures[i]$message),
                character(1)))
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
