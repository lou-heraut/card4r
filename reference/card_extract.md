# Calculer des variables hydroclimatiques

Calculer des variables hydroclimatiques

## Usage

``` r
card_extract(data, cards = c("QA", "QJXA"), date_col = "date", ...)
```

## Arguments

- data:

  Un data.frame : une colonne de dates, une colonne d'identifiant de
  série, et les colonnes numériques que les fiches demandent (\`Q\` pour
  le débit, \`T\` pour la température...).

- cards:

  Les fiches à calculer, par leur identifiant.

- date_col:

  Nom de la colonne de dates.

- ...:

  Passé tel quel à \`card.extract\` en Python : \`suffix\`,
  \`sampling_period\`, \`rename\`, \`metadata_only\`...

## Value

Une liste : \`data\`, une liste nommée de data.frames (un par fiche), et
\`meta\`, un data.frame d'une ligne par variable produite. \`meta\`
porte la définition employée (\`version\`, \`swhid\`) et le logiciel qui
a calculé (\`card_commit\`, \`stase_commit\`).
