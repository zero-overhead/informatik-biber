# Data Science mit Informatik-Biber-Daten

Try live demo: [biber-results-analytics.ipynb](https://mybinder.org/v2/gh/rcmlz/edu-binder-env/python?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252Fzero-overhead%252Finformatik-biber%26urlpath%3Dlab%252Ftree%252Finformatik-biber%252FData-Science%252FLectures%252Fbiber-results-analytics.ipynb%26branch%3Dmain)

(live demo uses [mybinder.org](https://mybinder.org/) + [nbgitpuller](https://nbgitpuller.readthedocs.io/en/latest/link.html?tab=binder))

## Datei Biber-Daten-Long.anonym.csv erstellen/aktualisieren

Dieses Repository einmalig clonen

```bash
git clone --depth 1 https://github.com/zero-overhead/informatik-biber
cd informatik-biber/Data-Science
tree
```

oder updaten

```bash
cd informatik-biber
git pull
cd Data-Science
tree
```

und anschliessend die Rohdaten vorbereiten

- Resultate als Excel-Datei von https://wettbewerb.informatik-biber.ch/admin/ herunterladen und im Ordner `Resultate` speichern
- Excel-Datei öffnen und alle Datensätze ohne Klasse entfernen (das sind nur "Tests") und die Excel-Datei wieder speichern
- danach alle Blätter der Excel-Datei mittels `Speichern unter` als  `CSV UTF-8`-Datei einzeln exportieren. Der Dateiname muss auf `_Einzel.csv` bzw. `_Gruppe.csv` enden.  Beispiel-Schema: `CH_KSZO_Wettbewerb_2024_Resultate_Einzel.csv`
- Es werden später alle Dateien, die auf `_Einzel.csv` oder `_Gruppe.csv` enden, automatisch eingelesen und zu einer grossen Datendatei zusammengeführt.
- `CH` (Land, 2 Buchstaben), `KSZO` (Schule, 4 Buchstaben) und `2024` (Jahr, 4 Zahlen) werden aus dem Dateinamen eingelesen und als Spalten verwendet.

Abschliessend die Datei `Biber-Daten-Long.anonym.csv` neu erstellen durch Aufruf von:

```bash
raku Tools/biber-preprocess.raku
```

oder mit optionalen Parametern

```bash
raku Tools/biber-preprocess.raku --input-dir=Resultate --input-csv-sep=";" --output-file=Daten/Biber-Daten-Long.csv --anonymize=True
```

Die Beispieldaten sollten diesen Output geben

```bash
Processing Resultate/CH_KSZZ_Wettbewerb_2025_Resultate_9-10_Einzel.csv
2 single rows
Processing Resultate/CH_BZAA_Wettbewerb_2025_Resultate_Einzel.csv
2 single rows
Processing Resultate/CH_KSXX_Wettbewerb_2021_Resultate_7-8_Einzel.csv
2 single rows
Processing Resultate/CH_KRAA_Wettbewerb_2023_Resultate_7-8_Einzel.csv
2 single rows
Processing Resultate/CH_KSYY_Wettbewerb_2025_Resultate_Gruppe.csv
3 team rows
Anonymize 11 students on columns: Name, Klasse, Schule, Team
Writing 193 answers to Daten/Biber-Daten-Long.anonym.csv
```

Die Datei `Biber-Daten-Long.anonym.csv` enthält nur noch anonymisierte Daten in Bezug auf Schule, Klasse und Schülernamen.

**Wichtig:** Beim Hochladen der Lernenden-Daten am Anfang des Biber-Jahres auf https://wettbewerb.informatik-biber.ch/admin/ für jeden Schüler über mehrere Jahre immer den gleichen Benutzernamen und die gleiche Klasse verwenden. Nur dann ist jeder Lernende mit Land+Schule+Klasse+Name über mehrere Jahre eindeutig identifizierbar und trotzdem anonym. Die Leistung einzelner SuS kann so über mehrere Jahre anonym nachverfolgt und analysiert werden.

Beispiel: für Susi Meier wird in jedem Jahr der gleiche Benutzername und die gleiche Klasse für den [Wettbewerb](https://wettbewerb.informatik-biber.ch/index.php?action=login) verwendet.

- Benutzername: susi.meier@student.schule.ch
- Klasse: G24b

## Raku

Installieren nach Anleitung: https://raku.org/install

Anschliessend Package installieren:

```bash
zef install Text::CSV:ver<0.022>:auth<zef:Tux> Markdown::Grammar File::Find
```

Zu Demonstrationszwecken ist ein Markdown-Beispiel enthalten, welches mit einem Script aus meiner "Unterrichts-Tools-Sammlung" (siehe `Tools/markdown-2-ipynb.raku`) in ein Jupyter-Notebook umgewandelt werden kann. In meinem Workflow sind Markdown-Dateien immer die "Golden Source of Truth".

```bash
cd Data-Science
raku Tools/markdown-2-ipynb.raku
```
