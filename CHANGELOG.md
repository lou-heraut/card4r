# Journal des modifications

Évolutions notables de `card4r`, front R du recueil
[card](https://github.com/lou-heraut/card). Format inspiré de [Keep a
Changelog](https://keepachangelog.com/fr/1.1.0/). Le corpus et le moteur
tiennent chacun le leur.

**Numérotation.** SemVer avec la convention du 0.x : tant que le premier
chiffre vaut 0, un changement incompatible incrémente le deuxième, le
reste incrémente le troisième.

**Quand couper ? Sur du contenu, jamais sur un calendrier.** Deux cas
suffisent ici :

- **une montée de `CARD_REF` ou de `STASE_REF`** (dans `R/zzz.R`) se
  publie, toujours : ces deux constantes décident quel code calcule, et
  un utilisateur doit pouvoir dire lequel a tourné en nommant une version
  de card4r. C'est la raison d'être de ce paquet, pas un détail interne ;
- sinon, on coupe **à la fin d'un chantier**, si un utilisateur
  remarquerait le changement.

Jamais au milieu d'un chantier. Le numéro vit dans `DESCRIPTION` et dans
`CITATION.cff`, et `tests/testthat/test-version.R` refuse le désaccord.

## Non publié

Rien depuis la 0.1.0.

## 0.1.0 (2026-08-05)

Première version.

### Ajouté

- **`card_extract()`, `card_trend()`, `card_list()`, `card_info()`** :
  un `data.frame` entre, des `data.frame` et leurs métadonnées sortent.
  Le corpus et le moteur ne sont pas réécrits en R, ils sont appelés, si
  bien qu'il n'existe qu'une définition de chaque variable.
- **Provisionnement automatique de Python** par `py_require()`
  (reticulate >= 1.41), qui télécharge au besoin l'interpréteur lui-même.
  Mesuré le 2026-08-05 sur une machine sans Python déclaré ni uv :
  provisionnement complet et calcul au bout. `RETICULATE_PYTHON` reste la
  voie pour désigner son propre environnement, et card4r ne déclare alors
  rien.
- **`card_config()`** : quel interpréteur répond, quelles versions de
  card et de stase, et leurs commits exacts.
- **Les dates traversent le pont sans se décaler**, seul endroit où R et
  pandas ne se comprennent pas d'eux-mêmes. Une colonne `Date` part en
  `POSIXct` UTC, ce qui arrive nativement en `datetime64` ; au retour,
  les horodatages sont relus en UTC avant de redevenir des `Date`, sans
  quoi un minuit du 1er janvier devenait le 31 décembre précédent.
- **Vérification croisée avec le paquet R historique** : les valeurs de
  `card4r` et de `CARD` coïncident à 1,8e-15, la précision machine, sur
  QA et VCN10. Le test tourne avec la suite, et se saute proprement si
  `CARD` n'est pas installé.

### Ce que le paquet ne fera pas

Écrire une fiche en R, et republier les fonctions hydro de card. Ces deux
limites sont ce qui le fait tenir en trois cents lignes plutôt qu'en un
second moteur à maintenir. Elles sont dites dans le README, à la place où
un utilisateur se pose la question.
