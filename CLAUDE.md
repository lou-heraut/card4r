# CLAUDE.md : card4r

## Contexte

`card4r` est le front R du recueil [card](../card/) : il **appelle** le
paquet Python par reticulate, il ne le réimplémente pas. Le corpus de
fiches YAML et le moteur [stase](../../EXstat_project/stase/) restent la
source unique, pour R comme pour Python.

Où lire quoi. Un rôle par fichier ; ne jamais recopier d'un fichier à
l'autre, renvoyer.
- `README.md` : ce que fait le paquet, comment on s'en sert, et ce qu'il
  ne fera pas.
- `CHANGELOG.md` : ce qui a changé, quand, et la règle de coupe de
  version propre à ce paquet.
- Le corpus, le moteur et le service ont chacun leur dépôt et leur
  documentation : ne rien en consigner ici, et réciproquement. Les
  principes documentaires communs aux quatre dépôts sont dans
  `../card/dev/decisions.md`.

> ## À NE JAMAIS FAIRE
>
> - **`note.txt` (et tout fichier de notes de l'utilisateur) : NE PAS
>   L'OUVRIR.** Ni Read, ni `cat`, ni `grep`, ni au détour d'un `git add`.
>   C'est son brouillon personnel : pas de lecture, pas de résumé, pas de
>   « au passage j'ai vu que ». Il n'entre dans aucune tâche sans une
>   demande explicite de sa part, fichier par fichier. Un en-tête qui dit
>   de ne pas lire est un ordre, pas une mise en garde à évaluer.
> - **Pas de `git add -A` ni de `git add .`** : stager nommément les
>   fichiers que l'on a soi-même modifiés. Ce qui traîne dans l'arbre de
>   travail appartient à l'utilisateur.
> - **Ne JAMAIS signaler un fichier non suivi.** Un fichier non suivi est
>   à l'utilisateur : brouillon, essai, sortie jetable. Il a le droit d'en
>   avoir, il n'a pas à s'en justifier, et le lui rappeler est une
>   nuisance. Pas de « au passage, j'ai vu que », pas de « je n'y touche
>   pas », pas de récapitulatif en fin de réponse. On n'en parle que s'il
>   en parle le premier. Le répertoire `bac/` est ignoré par git : c'est
>   là qu'on lui propose de déposer ce qu'il veut faire disparaître du
>   `git status`, une fois, sans y revenir.

## Structure

```
R/zzz.R    # le pont : py_require() et les refs ÉPINGLÉES de card et stase
R/card.R   # l'API R (4 fonctions), et le traitement des dates
tests/     # testthat ; les tests qui demandent Python se sautent sans lui
man/       # GÉNÉRÉ par roxygen2, ne pas éditer à la main
```

Vérifs après toute modif : `roxygen2::roxygenise(".")` si une docstring a
bougé, puis `testthat::test_local(".")`, puis `R CMD check`.

## La règle qui tient ce paquet

**Ce qui traverse le pont, c'est de la DONNÉE, jamais du code.** Un
`data.frame` entre, des `data.frame` et leurs métadonnées sortent.

Deux conséquences, à ne pas éroder :

- **pas de republication des fonctions hydro** de card
  (`compute_FDC`...) : elles sont la mécanique interne des fiches ;
- **pas d'écriture de fiche en R.** Une fiche est un YAML du corpus. Le
  jour où on voudrait faire traverser une fonction R comme `func`, le
  pont deviendrait ingérable, et le paquet cesserait d'être un pont pour
  devenir un second moteur à maintenir.

Une demande qui suppose l'une de ces deux choses se discute avec
l'utilisateur avant d'être codée, jamais contournée par un ajout local.

## Trois points d'implémentation à connaître

- **Les dates sont le premier endroit où R et pandas ne se comprennent
  pas.** Une colonne `Date` traverse en texte ; une `POSIXct` en UTC
  arrive nativement en `datetime64`. Au retour, les horodatages sans
  fuseau sont relus en UTC avant de redevenir des `Date`, sans quoi un
  minuit du 1er janvier devient le 31 décembre précédent. Les deux sens
  sont testés.
- **Les avertissements sont le second.** Python les imprime lui-même sur
  stderr, hors de portée de `suppressWarnings()` et de `tryCatch` ;
  `.avec_avertissements_r()` (dans `R/zzz.R`) les intercepte et les
  réémet en `warning()` R, et enveloppe les quatre fonctions publiques.
  Deux choses à ne pas défaire : l'import de `warnings` se fait avec
  `convert = FALSE`, sans quoi la liste de captures est copiée vide ; et
  les filtres de Python ne sont PAS touchés, sans quoi ses
  `DeprecationWarning` internes remonteraient à l'utilisateur.
- **`CARD_REF` et `STASE_REF` (dans `R/zzz.R`) sont des TAGS, jamais
  `main`.** Ce sont elles qui décident quel code calcule : une version de
  card4r doit toujours appeler le même. Les monter est un geste
  explicite, qui s'accompagne d'une version de card4r (cf. la règle de
  coupe du CHANGELOG).

## Versions et citation

Le numéro vit dans `DESCRIPTION` et dans `CITATION.cff`, et
`tests/testthat/test-version.R` refuse le désaccord. Quand couper :
première section du `CHANGELOG.md`. **Le proposer soi-même**,
l'utilisateur ne le demandera pas.

Un résultat porte déjà sa provenance : `res$meta` donne la version et le
`swhid` de chaque fiche, plus les commits exacts de card et de stase.
`card_config()` les affiche sans lancer de calcul.

## État

Cette section ne porte aucun état, elle dit où le lire : livré dans
`CHANGELOG.md`, et pour le reste de l'écosystème R (sort des paquets
historiques, gel de la référence) `../card/dev/plans/2026-08-05_r-ecosystem.md`.

Les paquets R historiques `../CARD-R/` et
`../../EXstat_project/EXstat/` **restent sans fichiers IA** : on peut y
lire, on n'y dépose rien.
