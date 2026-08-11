# Compute a whole family

You rarely want one variable. You want every low-flow indicator, or
every temperature indicator your data can feed. The collection is
queryable, so that is two lines rather than a list you maintain by hand.

``` r

library(card4r)
library(airGRdatasets)
```

## The data

[airGRdatasets](https://cran.r-project.org/package=airGRdatasets) ships
daily records for gauged French catchments, which is enough to run
without downloading anything. Three of them, chosen for contrast:

``` r

ids <- c("A273011002", "X031001001", "Y862000101")
do.call(rbind, lapply(ids, function(i) {
  d <- get(i)
  data.frame(id = i, name = d$Meta$Name, area_km2 = round(d$Meta$Area))
}))
#>           id                                           name area_km2
#> 1 A273011002                     La Bruche à Russ [Wisches]      224
#> 2 X031001001 La Durance à Embrun [La Clapière] - DREAL PACA     2283
#> 3 Y862000101             Le Taravo à Zigliara [Pont d'Abra]      332
```

card reads its input columns by name, so the only preparation is to give
them the names the cards use: `Q` for discharge in m³·s⁻¹, `R` for
precipitation, `T` for temperature, `ETP` for potential
evapotranspiration.
[`card_list()`](https://lou-heraut.github.io/card4r/reference/card_list.md)
and
[`card_info()`](https://lou-heraut.github.io/card4r/reference/card_info.md)
state what each card needs.

``` r

ts <- do.call(rbind, lapply(ids, function(i) {
  d <- get(i)$TS
  data.frame(id = i, date = as.Date(d$Date),
             R = d$Ptot, T = d$Temp, ETP = d$Evap,
             Q = d$Qls / 1000)          # airGRdatasets serves L/s
}))
str(ts)
#> 'data.frame':    21915 obs. of  6 variables:
#>  $ id  : chr  "A273011002" "A273011002" "A273011002" "A273011002" ...
#>  $ date: Date, format: "1999-01-01" "1999-01-02" ...
#>  $ R   : num  0 8.7 4.1 2.2 0 0 21.6 7.8 5.3 0.1 ...
#>  $ T   : num  -0.1 4.4 4.4 8.1 8.5 9.5 8.6 3.2 1 -1.3 ...
#>  $ ETP : num  0.2 0.3 0.4 0.5 0.5 0.5 0.5 0.3 0.2 0.1 ...
#>  $ Q   : num  5.47 5.16 6.34 6.29 6 5.35 5.46 13.3 11.3 10.1 ...
```

## Select a family, then compute it

Ask the collection for a family. Facets accept English or French, and
the [catalogue](https://lou-heraut.github.io/card/CARDS) lists the
values each one takes.

``` r

temp <- card_list(domain = "temperature")
nrow(temp)
#> [1] 40
```

Not all of those run on a temperature series alone: some compare
discharge to temperature. You do not have to know which, the listing
says so.

``` r

table(temp$input_vars)
#> 
#> Q_obs, Q_sim, T_obs                Q, T                   T 
#>                   1                   5                  34
```

``` r

temp <- temp[temp$input_vars == "T", ]
nrow(temp)
#> [1] 34
```

One row per **variable**. What you extract is a **card**, and one card
can produce several variables: the twelve `mean-TMA_*` are the monthly
columns of the single card `mean-TMA_month`. The `card` column holds
that name.

``` r

unique(temp$card)
#> [1] "mean-TA"         "mean-TMA_month"  "mean-TSA_season" "TA"             
#> [5] "TMA_month"       "TSA_season"
```

That is the whole gesture:

``` r

res <- card_extract(ts[, c("id", "date", "T")], cards = unique(temp$card))
res$data[["mean-TA"]]
#>           id   mean-TA
#> 1 A273011002  8.657035
#> 2 X031001001  3.305343
#> 3 Y862000101 11.639664
```

Which reads as a catchment gradient rather than as three numbers: the
Bruche drains the Vosges foothills, the Durance at Embrun is alpine, and
the Taravo is Corsican.

The metadata comes with it, one row per variable produced, saying which
card each one came from:

``` r

head(res$meta[, c("card", "variable_en", "unit_en", "name_en")], 3)
#>             card  variable_en unit_en
#> 1        mean-TA      mean-TA      °C
#> 2 mean-TMA_month mean-TMA_jan      °C
#> 3 mean-TMA_month mean-TMA_feb      °C
#>                                            name_en
#> 1 Inter-annual mean of the annual mean temperature
#> 2   Inter-annual mean of January mean temperatures
#> 3  Inter-annual mean of February mean temperatures
```

## The same two lines, anywhere in the collection

Nothing above is specific to temperature. Swap the facet and the input
column:

``` r

lf <- card_list(phenomenon = "low flows", output = "series")
lf <- lf[lf$input_vars == "Q", ]
c(variables = nrow(lf), cards = length(unique(lf$card)))
#> variables     cards 
#>        51        39
```

``` r

res <- card_extract(ts[, c("id", "date", "Q")], cards = unique(lf$card))
#> Warning: Grille month incomplète : 12 pas de temps manquants insérés (valeurs
#> NaN). Les lignes absentes comptent comme lacunes (na_pct, max_na_pct,
#> max_na_years).
#> Warning: Grille month incomplète : 9 pas de temps manquants insérés (valeurs
#> NaN). Les lignes absentes comptent comme lacunes (na_pct, max_na_pct,
#> max_na_years).
#> Warning: Grille month incomplète : 21 pas de temps manquants insérés (valeurs
#> NaN). Les lignes absentes comptent comme lacunes (na_pct, max_na_pct,
#> max_na_years).
head(res$data[["VCN10"]], 3)
#>           id       date  VCN10
#> 1 A273011002 1999-01-01 0.7554
#> 2 A273011002 2000-01-01 1.9040
#> 3 A273011002 2001-01-01 1.1680
```

[`card_trend()`](https://lou-heraut.github.io/card4r/reference/card_trend.md)
then tests every one of them, in one call:

``` r

tr <- card_trend(res)
tr$data[["VCN10"]][, c("id", "h", "p", "a")]
#>           id     h         p            a
#> 1 A273011002 FALSE 0.3225120 -0.014583889
#> 2 X031001001 FALSE 0.6476631  0.152461538
#> 3 Y862000101 FALSE 0.6778696  0.004905714
```

`h` is significance at the requested level, `0.1` by default, and `a`
the Sen slope per year. None of these three is significant over twenty
years, which is the honest answer for a record that short.

## Where to look next

This page shows a gesture, not an inventory. The variables themselves
are published as a catalogue, in
[English](https://lou-heraut.github.io/card/CARDS) and in
[French](https://lou-heraut.github.io/card/CARDS.fr), generated from the
cards so that it cannot drift from them. `card_info("VCN10")` draws a
single card, step by step, in your console.
