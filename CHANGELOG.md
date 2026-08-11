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

Rien depuis la 0.1.1.

## 0.1.1 (2026-08-11)

### Ajouté

- **Un tag épinglé est confronté à ce qui répond vraiment (2026-08-11).**
  `CARD_REF` et `STASE_REF` décident quel code calcule, et la promesse du
  paquet est que deux personnes sur la même version de card4r exécutent
  le même. Rien ne le vérifiait : `card_config()` était la seule des cinq
  fonctions exportées sans aucun test, alors que c'est celle que le README
  désigne pour répondre à la question. Le test compare maintenant les
  versions annoncées aux refs épinglées, et se saute quand
  `RETICULATE_PYTHON` impose un interpréteur, où elles ne s'appliquent
  pas.

### Modifié

- **`CARD_REF` monte en `v0.4.1` et `STASE_REF` en `v0.6.2`
  (2026-08-11).** C'est ce qui force cette version : ces deux constantes
  décident quel code calcule, et leur montée se publie toujours, sans
  quoi personne ne peut dire quel corpus a répondu en nommant une version
  de card4r. Ce que card4r gagne au passage se lit dans les journaux de
  card et de stase, pas ici : côté corpus, `list_cards` ne rend plus
  d'accolade de gabarit à qui cherche une variable ; côté moteur, deux
  correctifs d'emballage. Aucune valeur ne bouge.

- **Les avertissements de card et de stase arrivent en `warning()` R
  (2026-08-11).** Ils étaient imprimés par Python lui-même sur la sortie
  d'erreur, avec le chemin du `.py` qui les émettait, et surtout ils
  échappaient à R : ni `suppressWarnings()`, ni `options(warn = 2)`, ni
  `tryCatch` n'avaient prise dessus. Un utilisateur bouclant sur trois
  cents stations n'avait aucun moyen de les couper. Ils sont désormais
  interceptés par `warnings.catch_warnings()` et réémis en conditions R,
  dédoublonnés, une extraction multi-fiches répétant le même message une
  fois par fiche.

  Les filtres de Python sont laissés **intacts** : ses défauts taisent
  déjà les `DeprecationWarning` de pandas et de numpy, que forcer à
  remonter aurait rendu bavard un calcul qui ne l'était pas. C'est le
  second endroit où R et Python ne se comprennent pas d'eux-mêmes, après
  les dates, et il est traité au même endroit et de la même façon.

- **L'attribut que `card_extract()` laisse pour `card_trend()` s'appelle
  ce qu'il est (2026-08-11).** Il se nommait `py` et son commentaire
  annonçait « l'objet Python » ; c'est une liste R ordinaire
  (`is_py_object()` vaut `FALSE`), et l'erreur de `card_trend()` exigeait
  un résultat « produit dans la même session R » alors qu'un aller-retour
  par `saveRDS()` fonctionne. Il devient `table_card`, et son commentaire
  dit sa vraie raison d'être : c'est la table d'AVANT
  `.rendre_les_dates()`, dont les dates sont encore en `POSIXct` et
  repartent donc vers Python en `datetime64` plutôt qu'en texte. Ce que
  reçoit l'appelant est inchangé, dates en `Date` comprises.

- **Le README ne compte plus les fiches par facette, ni les lignes du
  paquet (2026-08-11).** Les exemples de `card_list()` annonçaient
  « 114 variables », « 267 », « 83 », recopiés du README de card, où la
  règle veut pourtant que le seul décompte soit celui des marqueurs
  `<!-- cards:count -->`. Ils devenaient faux en silence à la première
  montée de `CARD_REF`. Ils disent maintenant ce que la facette
  sélectionne. La promesse « three hundred lines », elle, ne servait pas
  l'argument qui la portait : ce qui tient ce paquet est qu'il est un
  pont, pas sa longueur.

- **Le README suit la structure de celui de card, sans en recopier le
  contenu (2026-08-06).** Deux niveaux, les mêmes grandes parties, et
  l'exemple tourne sur les mêmes données réelles : l'Yzeron à Craponne,
  chargé depuis Hub'Eau. Il affiche donc **les mêmes nombres que la
  version Python, au dernier chiffre**, ce qui est l'argument central du
  paquet et se démontre mieux qu'il ne s'explique.

  Ce qui appartient au CORPUS est renvoyé plutôt que recopié : le
  catalogue, la grammaire des noms, l'anatomie d'une fiche, l'écriture
  d'une fiche. Deux textes disant la même chose sur le même corpus
  finiraient par diverger, et c'est card qui en est la source. Le README
  fait 225 lignes là où une duplication en aurait fait 500.

  La section d'installation dit aussi ce qu'elle taisait : chaque version
  de card4r épingle les versions exactes de card et de stase qu'elle
  appelle, par tag et non par branche, donc deux personnes sur la même
  version de card4r exécutent le même code. `card_config()` le montre.

### Corrigé

- **Le README annonçait deux commits qui étaient faux dès le commit
  suivant (2026-08-11).** Le bloc `card_config()` écrivait les quarante
  caractères entiers du commit de card et de celui de stase, et la table
  `meta` les répétait, relevés au moment où l'exemple a été joué. Or ces
  deux blocs sont exactement ceux qui enseignent qu'un commit ne ment
  jamais, contrairement à un numéro de version. Aucune garde n'était
  possible : card ne publie AUCUN commit depuis une copie de travail
  modifiée, si bien qu'un test comparant le README au réel échouerait
  pendant tout le travail. Les valeurs sont donc élidées par un `…`,
  comme le chemin de l'interpréteur l'était déjà dans le même bloc, et
  comme le `swh:1:cnt:` qui les jouxte. Même correction dans le README de
  card, où le commit était déjà tronqué. Ce qui reste écrit en dur y est
  justifié : un `swh:1:cnt:` identifie le fichier de fiche et ne bouge
  que si le YAML bouge.

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
