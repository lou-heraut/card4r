# Tester la stationnarité d'une extraction

Tester la stationnarité d'une extraction

## Usage

``` r
card_trend(x, ...)
```

## Arguments

- x:

  Le résultat de \[card_extract()\].

- ...:

  Passé tel quel à \`card.trend\` : \`level\`, \`mk\`, \`period\`...

## Value

Même forme que \[card_extract()\] : \`data\` et \`meta\`. La colonne
\`h\` dit si la tendance est significative, \`a\` est la pente de Sen.
