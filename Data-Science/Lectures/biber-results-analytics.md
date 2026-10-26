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
anzahl = 3
show_worst_scores = False

punkte = (
    df.groupby(
        ["Jahr", "Klassenstufe", "Schule", "Klasse", "Name"], as_index=False
    )["Punkte"]
    .sum()
)

punkte["Rang"] = (
    punkte.groupby(["Jahr", "Klassenstufe"])["Punkte"]
    .rank(method="min", ascending=show_worst_scores)
)

rangliste = (
    punkte[punkte["Rang"] <= anzahl]
    [["Jahr", "Klassenstufe", "Schule", "Klasse", "Name", "Punkte"]]
    .sort_values(
        ["Jahr", "Klassenstufe", "Punkte", "Klasse", "Name"],
        ascending=[True, False, show_worst_scores, True, True]
    )
    .reset_index(drop = True)
)

rangliste[rangliste['Jahr'] == 2025]
```

## Grafiken erstellen

```python
df.plot(kind="box", column="Punkte", by=['Jahr', 'Klassenstufe'], showmeans=True, rot=90)
```
