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

## mit groupby oder pivot_table analysieren

```python
df[['Jahr', 'Klassenstufe', 'Punkte']]\
  .groupby(['Jahr', 'Klassenstufe'])\
  .mean()
```

```python
df[["Jahr", "Klassenstufe", "Schule", "Punkte"]]\
    .groupby(["Jahr", "Schule", "Klassenstufe"], observed=True)\
    .mean()\
    .sort_values(["Jahr", "Punkte"], ascending=[True, False])
```

```python
beste = 1

punkte = (
    df.groupby(
        ["Jahr", "Klassenstufe", "Schule", "Klasse", "Name"],
        observed=True,
        as_index=False
    )["Punkte"]
    .sum()
)

punkte["Rang"] = (
    punkte.groupby(["Jahr", "Klassenstufe"], observed=True)["Punkte"]
    .rank(method="min", ascending=False)
)

leaderboard = (
    punkte[punkte["Rang"] <= beste]
    [["Jahr", "Klassenstufe", "Schule", "Klasse", "Name", "Punkte"]]
    .sort_values(
        ["Jahr", "Klassenstufe", "Punkte", "Klasse", "Name"],
        ascending=[True, False, False, True, True]
    )
    .reset_index(drop=True)
)

leaderboard
```

```python
df.pivot_table(
    columns = ['Klassenstufe', 'Schule'],
    index=['Jahr', 'Team'],
    values='Punkte',
    aggfunc='mean'
)
```

## Grafiken erstellen

```python
df.plot(kind="box", column="Punkte", by=['Jahr', 'Klassenstufe'], showmeans=True, rot=90)
```
