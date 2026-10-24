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

## mit groupby oder pivot_table analysieren

```python
df[['Jahr', 'Schuljahre', 'Punkte']]\
  .groupby(['Jahr', 'Schuljahre'])\
  .mean()
```

```python
df[["Jahr", "Schuljahre", "Schule", "Punkte"]]\
    .groupby(["Jahr", "Schule", "Schuljahre"], observed=True)\
    .mean()\
    .sort_values(["Jahr", "Punkte"], ascending=[True, False])
```

```python
df.pivot_table(
    columns = ['Schuljahre', 'Schule'],
    index=['Jahr', 'Team'],
    values='Punkte',
    aggfunc='mean'
)
```

## Grafiken erstellen

```python
df.plot(kind="box", column="Punkte", by=['Jahr', 'Schuljahre'], showmeans=True, rot=90)
```
