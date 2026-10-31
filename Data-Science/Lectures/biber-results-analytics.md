# Biber Daten analysieren

## Daten importieren

Pandas-Modul laden.

```python
import pandas as pd
```

Dateien einlesen

```python
df = pd.read_csv("../Daten/Biber-Daten-Long.anonym.csv")
```

oder für komprimierte Rohdaten-Dateien

```python
df = pd.read_csv("../Daten/Biber-Daten-Long.anonym.csv.gz", compression='gzip')
```

## Überblick verschaffen

```python
df.head()
```

```python
df.tail(3)
```

```python
df.describe()
```

```python
df.info()
```

## Vorbereitung

Bonuspunkte herausfiltern

```python
f = df['Aufgabe'] != 'Bonus'
df = df[f]
```

Teams markieren

```python
df["Team"] = df["Teamname"] != "none"
```

Überprüfen

```python
df.info()
```

```python
df
```

## mit groupby oder pivot_table analysieren

```python
df[['Jahr', 'Klassenstufe', 'Punkte']]\
  .groupby(['Jahr', 'Klassenstufe'])\
  .mean()
```

```python
df[["Jahr", "Klassenstufe", "Schule", "Punkte"]]\
    .groupby(["Jahr", "Schule", "Klassenstufe"])\
    .mean()\
    .sort_values(["Jahr", "Punkte"], ascending=[True, False])
```

```python
df.pivot_table(
    index = ['Klassenstufe', 'Schule'],
    columns = ['Jahr', 'Team'],
    values='Punkte',
    aggfunc='mean'
)
```

```python
aufgabenauswahl =   (df['Aufgabe'] == 'Schichte nach Dichte!') \
                  | (df['Aufgabe'] == 'SOS aus den Bergen')

df[aufgabenauswahl]\
  .groupby( ['Jahr', 'Aufgabe', 'Klassenstufe'] )['Punkte']\
  .agg(
    count    = lambda x: x.count(),
    min      = lambda x: x.min(),
    q01      = lambda x: x.quantile(0.01),
    q05      = lambda x: x.quantile(0.05),
    q25      = lambda x: x.quantile(0.25),
    q50      = lambda x: x.quantile(0.50),
    q75      = lambda x: x.quantile(0.75),
    q95      = lambda x: x.quantile(0.95),
    q99      = lambda x: x.quantile(0.99),
    max      = lambda x: x.max(),
    mean     = lambda x: round(x.mean(), 1),
    std      = lambda x: round(x.std(), 1),
    kurtosis = lambda x: round(x.kurtosis(), 1),
    sum      = lambda x: x.sum(),
  )\
  .sort_values(['Jahr', 'Aufgabe', 'Klassenstufe'], ascending=[True, True, True])
```

```python
schwierigste = True
anzahl_aufgaben = 5
nur_klassenstufe = (df['Klassenstufe'] == '9+10') | (df['Klassenstufe'] == '11+12+13')

df[nur_klassenstufe].groupby( ['Jahr', 'Aufgabe'] )['Punkte']\
  .agg(
    count    = lambda x: x.count(),
    min      = lambda x: x.min(),
    q01      = lambda x: x.quantile(0.01),
    q05      = lambda x: x.quantile(0.05),
    q25      = lambda x: x.quantile(0.25),
    q50      = lambda x: x.quantile(0.50),
    q75      = lambda x: x.quantile(0.75),
    q95      = lambda x: x.quantile(0.95),
    q99      = lambda x: x.quantile(0.99),
    max      = lambda x: x.max(),
    mean     = lambda x: round(x.mean(), 1),
    std      = lambda x: round(x.std(), 1),
    kurtosis = lambda x: round(x.kurtosis(), 1),
    sum      = lambda x: x.sum(),
  )\
  .sort_values(['mean'], ascending=[schwierigste]).head(anzahl_aufgaben)
```
  
```python
anzahl = 3
calculate_worst_scores = False

punkte = (
    df.groupby(
        ["Jahr", "Klassenstufe", "Schule", "Klasse", "Name"], as_index=False
    )["Punkte"]
    .sum()
)

punkte["Rang"] = (
    punkte.groupby(["Jahr", "Klassenstufe"])["Punkte"]
    .rank(method="min", ascending=calculate_worst_scores)
)

rangliste = (
    punkte[punkte["Rang"] <= anzahl]
    [["Jahr", "Klassenstufe", "Schule", "Klasse", "Name", "Punkte"]]
    .sort_values(
        ["Jahr", "Klassenstufe", "Punkte", "Klasse", "Name"],
        ascending=[True, False, calculate_worst_scores, True, True]
    )
    .reset_index(drop = True)
)

rangliste.tail(10)
```

```python
rangliste[rangliste['Jahr'] == 2025]
```

## Grafiken erstellen

```python
df.plot(kind="box", column="Punkte", by=['Jahr', 'Klassenstufe'], showmeans=True, rot=90)
```
