# card4r

**card4r** donne accès depuis R au recueil de fiches hydroclimatiques
[card](https://github.com/lou-heraut/card) : étiages, crues,
saisonnalité, changement climatique, sur vos propres données.

Le corpus et le moteur ne sont pas réécrits en R, ils sont **appelés**.
Un `data.frame` entre, des `data.frame` et leurs métadonnées sortent.

## Installation

```r
# install.packages("remotes")
remotes::install_github("lou-heraut/card4r")
```

Il n'y a rien d'autre à installer. Au premier appel, card4r provisionne
tout seul l'environnement Python dont il a besoin (interpréteur, numpy,
pandas, scipy, puis `card` et `stase`), via
[reticulate](https://rstudio.github.io/reticulate/). Comptez quelques
centaines de mégaoctets et du réseau, une seule fois.

Si vous préférez fournir votre propre Python, désignez-le avant de
charger le paquet et card4r ne provisionnera rien :

```r
Sys.setenv(RETICULATE_PYTHON = "/chemin/vers/python")
```

C'est aussi la voie à suivre derrière un proxy qui bloque le
téléchargement, ou sur un poste sans accès réseau.

## Démarrage rapide

```r
library(card4r)

# une chronique journalière : une colonne de dates, une colonne
# d'identifiant de série, et les colonnes que les fiches demandent
# (`Q` pour le débit, `T` pour la température...).
data <- data.frame(date = dates, Q = debits, id = "ma_station")

res <- card_extract(data, cards = c("QA", "VCN10"))

head(res$data$VCN10, 3)
#           id       date    VCN10
# 1 ma_station 1970-01-01 2.150247
# 2 ma_station 1971-01-01 3.421462
# 3 ma_station 1972-01-01 2.333131
```

`res$meta` porte une ligne par variable produite : unité, nom,
classification, et de quoi retrouver le calcul (voir plus bas).

## Tendance

```r
tr <- card_trend(res)
tr$data$VCN10[, c("id", "h", "p", "a", "a_relative")]
#           id    h          p            a a_relative
# 1 ma_station TRUE 0.04289009 -0.007849947 -0.3451902
```

`h` dit si la tendance est significative au seuil demandé, `a` est la
pente de Sen dans l'unité de la variable et par an, `a_relative` la même
en pourcentage de la moyenne.

## Trouver sa fiche

```r
card_list()                            # toutes les variables
card_list(phenomenon = "basses eaux")  # par phénomène (fr ou en)
card_info("VCN10")                     # la fiche, dessinée
```

Le catalogue complet se consulte aussi
[en ligne](https://lou-heraut.github.io/card/CARDS.html).

## Ce qu'un résultat dit de lui-même

```r
res$meta[, c("variable_en", "version", "card_version", "card_commit")]
#   variable_en version card_version                              card_commit
# 1          QA     1.0        0.4.0 60812eb3869e2bf6b979898c170b0e72ffd89a56
```

`version` est celle de la **fiche**, qui change quand ses sorties
changent ; `card_commit` et `stase_commit` identifient exactement le
**logiciel** qui a calculé. Un résultat exporté dit donc avec quoi il a
été produit, ce qui suffit à le citer ou à le rejouer. `card_config()`
affiche la même chose sans lancer de calcul.

## Ce que card4r ne fait pas, et ne fera pas

- **Écrire une fiche en R.** Une fiche est un fichier YAML du corpus, et
  c'est ce qui permet qu'il n'y ait qu'une définition pour R et pour
  Python. Contribuer une fiche se fait dans
  [card](https://github.com/lou-heraut/card).
- **Republier les fonctions hydro** (`compute_FDC`, `get_BFI`...). Elles
  restent la mécanique interne des fiches.

Ces deux limites ne sont pas des manques : ce sont elles qui font tenir
le paquet en trois cents lignes plutôt qu'en un second moteur à
maintenir.

## Et le paquet CARD historique ?

[CARD](https://github.com/lou-heraut/CARD-R) est le paquet R d'origine,
d'où card vient. Il reste installable et n'est pas retiré, mais il
n'évolue plus : la version en cours de développement est du côté de card.

La bascule ne change pas vos résultats : **vérifié le 2026-08-05, les
valeurs de `card4r` et de `CARD` coïncident à 1,8e-15 près**, soit la
précision machine, et ce test tourne avec la suite du paquet.

| CARD (R) | card4r |
|---|---|
| `CARD_extraction(data, CARD_name = ...)` | `card_extract(data, cards = ...)` |
| `CARD_list_all()` | `card_list()` |
| `CARD_management(...)` | `card_info(...)` |

Les arguments `expand_overwrite`, `rmNApct`, `rm_duplicates` et `dev` de
`CARD_extraction` n'ont pas d'équivalent : ils ont disparu au portage.
card4r ne les accepte donc pas, plutôt que de les ignorer en silence.

## L'écosystème

| | |
|---|---|
| [card](https://github.com/lou-heraut/card) | le recueil de fiches, en Python |
| [stase](https://github.com/lou-heraut/stase) | le moteur d'agrégation et de tendance |
| **card4r** | le même recueil, appelé depuis R (vous êtes ici) |
| [card-api](https://github.com/lou-heraut/card-api) | le service web, sur les débits Hub'Eau |
| [CARD-R](https://github.com/lou-heraut/CARD-R) · [EXstat](https://github.com/lou-heraut/EXstat) | les paquets R historiques, remplacés |

## Licence et citation

GPL-3. Le corpus, le moteur et ce paquet ont chacun leur `CITATION.cff`.
Citez la ou les **fiches** employées avec leur version, que `res$meta`
vous donne.
