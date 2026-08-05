# card4r

**card4r** gives R access to the [card](https://github.com/lou-heraut/card)
collection of hydroclimatic variables: low flows, floods, seasonality,
climate change, computed on your own data.

The collection and the engine are not rewritten in R, they are **called**.
A `data.frame` goes in, `data.frame`s and their metadata come out.

## Installation

```r
# install.packages("remotes")
remotes::install_github("lou-heraut/card4r")
```

There is nothing else to install. On the first call, card4r provisions
the Python environment it needs on its own (interpreter, numpy, pandas,
scipy, then `card` and `stase`), through
[reticulate](https://rstudio.github.io/reticulate/). Expect a few hundred
megabytes and a network connection, once.

If you would rather supply your own Python, point at it before loading
the package and card4r will provision nothing:

```r
Sys.setenv(RETICULATE_PYTHON = "/path/to/python")
```

That is also the way to go behind a proxy that blocks the download, or on
a machine without network access.

## Quick start

```r
library(card4r)

# a daily time series: a date column, a series identifier column, and the
# columns the cards ask for (`Q` for discharge, `T` for temperature...).
data <- data.frame(date = dates, Q = discharge, id = "my_station")

res <- card_extract(data, cards = c("QA", "VCN10"))

head(res$data$VCN10, 3)
#           id       date    VCN10
# 1 my_station 1970-01-01 2.150247
# 2 my_station 1971-01-01 3.421462
# 3 my_station 1972-01-01 2.333131
```

`res$meta` holds one row per variable produced: unit, name,
classification, and what it takes to trace the computation (see below).

## Trend

```r
tr <- card_trend(res)
tr$data$VCN10[, c("id", "h", "p", "a", "a_relative")]
#           id    h          p            a a_relative
# 1 my_station TRUE 0.04289009 -0.007849947 -0.3451902
```

`h` tells whether the trend is significant at the requested level, `a` is
the Sen slope in the unit of the variable per year, `a_relative` the same
as a percentage of the mean.

## Finding a card

```r
card_list()                          # every variable
card_list(phenomenon = "low flows")  # by phenomenon (English or French)
card_info("VCN10")                   # the card, drawn
```

The full catalogue is also
[online](https://lou-heraut.github.io/card/CARDS.html).

## What a result says about itself

```r
res$meta[, c("variable_en", "version", "card_version", "card_commit")]
#   variable_en version card_version                              card_commit
# 1          QA     1.0        0.4.0 7ede9638e44e00daea969d7a9797cf773e891ce8
```

`version` is that of the **card**, which changes when its outputs change;
`card_commit` and `stase_commit` identify exactly the **software** that
computed. An exported result therefore says what produced it, which is
what it takes to cite it or to replay it. `card_config()` prints the same
without running a computation.

## What card4r does not do, and will not do

- **Write a card in R.** A card is a YAML file of the collection, and
  that is what keeps a single definition for both R and Python.
  Contributing a card happens in
  [card](https://github.com/lou-heraut/card).
- **Re-export the hydrological functions** (`compute_FDC`, `get_BFI`...).
  They remain the internal machinery of the cards.

These two limits are not gaps: they are what keeps the package at three
hundred lines instead of a second engine to maintain.

## What about the historical CARD package?

[CARD](https://github.com/lou-heraut/CARD-R) is the original R package,
where card comes from. It still installs and is not going away, but it is
no longer developed: the living version is on the card side.

Switching does not change your results: **checked on 2026-08-05, values
from `card4r` and from `CARD` match to 1.8e-15**, machine precision, and
that test runs with the package suite.

| CARD (R) | card4r |
|---|---|
| `CARD_extraction(data, CARD_name = ...)` | `card_extract(data, cards = ...)` |
| `CARD_list_all()` | `card_list()` |
| `CARD_management(...)` | `card_info(...)` |

The `expand_overwrite`, `rmNApct`, `rm_duplicates` and `dev` arguments of
`CARD_extraction` have no counterpart: they went away with the port.
card4r does not accept them, rather than ignore them silently.

## The ecosystem

| | |
|---|---|
| [card](https://github.com/lou-heraut/card) | the card collection, in Python |
| [stase](https://github.com/lou-heraut/stase) | the aggregation and trend engine |
| **card4r** | the same collection, called from R (you are here) |
| [card-api](https://github.com/lou-heraut/card-api) | the web service, on Hub'Eau discharge data |
| [CARD-R](https://github.com/lou-heraut/CARD-R) · [EXstat](https://github.com/lou-heraut/EXstat) | the historical R packages, superseded |

## Licence and citation

GPL-3. The collection, the engine and this package each have their own
`CITATION.cff`. Cite the **cards** you used, with their version, which
`res$meta` gives you.
