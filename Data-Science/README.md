## Datei Biber-Daten-Long.anonym.csv erstellen/aktualisieren

Dieses Repository clonen

```bash
git clone --depth 1 https://github.com/zero-overhead/informatik-biber
cd informatik-biber/Data-Science
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
cd informatik-biber/Data-Science
raku Tools/biber-preprocess.raku --input-dir=Resultate --output-file=Daten/Biber-Daten-Long.csv
```

Die Beispieldaten sollten diesen Output geben

```bash
Processing Resultate/CH_BZAA_Wettbewerb_2025_Resultate_Einzel.csv
2 rows
Processing Resultate/CH_KSXX_Wettbewerb_2021_Resultate_7-8_Einzel.csv
2 rows
Processing Resultate/CH_KSYY_Wettbewerb_2025_Resultate_Gruppe.csv
3 rows
Writing 119 rows to Daten/Biber-Daten-Long.anonym.csv
```

Die Datei `Biber-Daten-Long.anonym.csv` enthält nur noch anonymisierte Daten in Bezug auf Schule, Klasse und Schülernamen.

**Wichtig:** Beim Hochladen der Lernenden-Daten am Anfang des Biber-Jahres auf https://wettbewerb.informatik-biber.ch/admin/ für jeden Schüler über mehrere Jahre immer den gleichen Benutzernamen und die gleiche Klasse verwenden. Nur dann ist jeder Lernende mit Land+Schule+Klasse+Name über mehrere Jahre eindeutig identifizierbar und trotzdem anonym. Die Leistung einzelner SuS kann dann über mehrere Jahre nachverfolgt und anonym analysiert werden.

Beispiel: für Susi Meier wird in jedem Jahr der gleiche Benutzername und die gleiche Klasse für den [Wettbewerb](https://wettbewerb.informatik-biber.ch/index.php?action=login) verwendet.

- Benutzername: susi.meier@student.schule.ch
- Klasse: G24b


## Raku

Installieren nach Anleitung: https://raku.org/install

Anschliessend Package installieren:

```bash
zef install Text::CSV:ver<0.022>:auth<zef:Tux>
```
