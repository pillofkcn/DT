# Falcon Chinook ETL Projekt

## Projektový prehľad
**Falcon Chinook ETL Project** je dátový sklad a ETL pipeline navrhnutý na extrakciu údajov z databázy Chinook, ich transformáciu do dimenzionálnych modelov a načítanie do dátového skladu. Projekt využíva Snowflake SQL na správu stagingových, dimenzionálnych a faktových tabuliek.

## Štruktúra projektu
### Nastavenie databázy a schémy
- **Databáza**: `FALCON_CHINOOK`
- **Schéma**: `FALCON_SCHEME`

Príkazy:
```sql
CREATE DATABASE IF NOT EXISTS FALCON_CHINOOK;
USE DATABASE FALCON_CHINOOK;

CREATE SCHEMA IF NOT EXISTS FALCON_SCHEME;
USE SCHEMA FALCON_SCHEME;
```

### Stagingové tabuľky

<img src="https://github.com/user-attachments/assets/14afcc77-eb77-4c45-be9e-86882a0abae3" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">

Stagingové tabuľky slúžia ako medzivrstva pre surové údaje reprezentované ER diagramom vyššie. Projekt zahŕňa nasledujúce stagingové tabuľky:

1. **staging_dim_genre**: Ukladá žánre skladieb s atribútmi `GenreId` (primárny kľúč) a `Name` (názov žánru).
2. **staging_dim_mediatype**: Obsahuje typy médií s atribútmi `MediaTypeId` (primárny kľúč) a `Name` (názov typu médií).
3. **staging_dim_artist**: Obsahuje údaje o interpretovi s `ArtistId` (primárny kľúč) a `Name` (meno interpreta).
4. **staging_dim_album**: Obsahuje údaje o albumoch, vrátane `AlbumId` (primárny kľúč), `Title` (názov albumu) a cudzieho kľúča `ArtistId`, ktorý odkazuje na interpretov.
5. **staging_dim_track**: Ukladá skladby s detailmi ako `TrackId`, `Name`, `AlbumId`, `MediaTypeId`, `GenreId`, `Composer`, `Milliseconds`, `Bytes` a `UnitPrice`.
6. **staging_dim_customer**: Obsahuje údaje o zákazníkoch, ako meno, adresu, krajinu, email a ďalšie kontaktné informácie.
7. **staging_dim_employee**: Ukladá údaje o zamestnancoch vrátane `EmployeeId`, mena, titulu, adresy a nadriadeného.
8. **staging_dim_playlist**: Obsahuje údaje o playlistoch s `PlaylistId` a `Name`.
9. **staging_dim_playlisttrack**: Spojovacia tabuľka medzi playlistmi a skladbami.
10. **staging_fact_invoice**: Obsahuje fakturačné údaje, ako sú ID zákazníka, dátum faktúry, adresa a celková suma.
11. **staging_fact_invoiceline**: Ukladá riadkové položky faktúr s detailmi ako `InvoiceLineId`, `InvoiceId`, `TrackId`, jednotková cena a množstvo.


### Načítanie údajov
Údaje sa načítavajú do stagingových tabuliek pomocou príkazu `COPY INTO`. Predpokladá sa, že CSV súbory sú nahrané v Snowflake stage `FALCON_CHINOOK_DATA`.

Príklad príkazu:
```sql
COPY INTO staging_dim_artist
FROM @FALCON_CHINOOK_DATA/chinook_table_artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

### Dimenzionálne a faktové tabuľky

<img src="https://github.com/user-attachments/assets/0e9b3971-ed3f-41ee-8ec4-6b0d596be930" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">

#### Dimenzionálne tabuľky

1. **dim_customer**
   - SCD: 1
   - Transformácia:
     - Získava údaje zo stagingovej tabuľky `staging_dim_customer`.
     - Premenúva atribúty na čitateľnejšie názvy ako `customer_id`, `first_name` a `last_name`.
     - Odstraňuje nepotrebné atribúty a normalizuje údaje.
   - SQL kód:
```sql
CREATE OR REPLACE TABLE dim_customer AS
SELECT 
    CustomerId AS customer_id,
    FirstName AS first_name,
    LastName AS last_name,
    Company AS company,
    Address AS address,
    City AS city,
    State AS state,
    Country AS country,
    PostalCode AS postal_code,
    Phone AS phone,
    Fax AS fax,
    Email AS email
FROM staging_dim_customer;
```
   - Účel: Táto tabuľka umožňuje identifikovať zákazníkov a ich demografické údaje pre analytické účely.

2. **dim_track**
   - SCD: 1
   - Transformácia:
     - Spája údaje zo stagingových tabuliek `staging_dim_track`, `staging_dim_album`, `staging_dim_artist`, `staging_dim_mediatype` a `staging_dim_genre`.
     - Obsahuje informácie ako názov skladby, názov albumu, meno interpreta, typ médií a žáner.
     - Normalizuje ceny a kontextualizuje údaje.
   - SQL kód:
   ```sql
   CREATE OR REPLACE TABLE dim_track AS
   SELECT 
       t.TrackId AS track_id,
       t.Name AS name,
       a.Title AS album_title,
       ar.Name AS artist_name,
       m.Name AS media_type,
       g.Name AS genre,
       t.Composer AS composer,
       t.Milliseconds AS milliseconds,
       t.Bytes AS bytes,
       t.UnitPrice AS unit_price
   FROM staging_dim_track t
   LEFT JOIN staging_dim_album a ON t.AlbumId = a.AlbumId
   LEFT JOIN staging_dim_artist ar ON a.ArtistId = ar.ArtistId
   LEFT JOIN staging_dim_mediatype m ON t.MediaTypeId = m.MediaTypeId
   LEFT JOIN staging_dim_genre g ON t.GenreId = g.GenreId;
   ```
   - Účel: Zabezpečuje kontext skladieb vrátane ich albumov, interpretov a žánrov.

3. **dim_employee**
   - SCD: 2
   - Transformácia:
     - Využíva údaje zo stagingovej tabuľky `staging_dim_employee`.
     - Pridáva údaje o nadriadenom zamestnancovi pomocou self-join.
     - Obsahuje kompletné kontaktné údaje zamestnancov.
   - SQL kód:
   ```sql
   CREATE OR REPLACE TABLE dim_employee AS
   SELECT 
       e.EmployeeId AS employee_id,
       CONCAT(e.FirstName, ' ', e.LastName) AS full_name,
       e.Title AS title,
       CONCAT(s.FirstName, ' ', s.LastName) AS supervisor_name,
       e.HireDate AS hire_date,
       e.Address AS address,
       e.City AS city,
       e.State AS state,
       e.Country AS country,
       e.PostalCode AS postal_code,
       e.Email AS email
   FROM staging_dim_employee e
   LEFT JOIN staging_dim_employee s ON e.ReportsTo = s.EmployeeId;
   ```
   - Účel: Poskytuje informácie o štruktúre tímu a kontaktné údaje zamestnancov.

4. **dim_playlist**
   - SCD: 1
   - Transformácia:
     - Kopíruje údaje zo stagingovej tabuľky `staging_dim_playlist`.
     - Odstraňuje duplicitné a nadbytočné informácie.
   - SQL kód:
   ```sql
   CREATE OR REPLACE TABLE dim_playlist AS
   SELECT 
       PlaylistId AS playlist_id,
       Name AS name
   FROM staging_dim_playlist;
   ```
   - Účel: Umožňuje analyzovať používateľské playlisty.

5. **dim_date**
   - SCD: 0
   - Transformácia:
     - Vytvára jedinečné dátumy zo `InvoiceDate` v tabuľke `staging_fact_invoice`.
     - Extrahuje časové komponenty ako deň, mesiac, rok a štvrťrok.
   - SQL kód:
   ```sql
   CREATE OR REPLACE TABLE dim_date AS
   SELECT DISTINCT 
       CAST(InvoiceDate AS DATE) AS date,
       EXTRACT(DAY FROM InvoiceDate) AS day,
       EXTRACT(MONTH FROM InvoiceDate) AS month,
       EXTRACT(YEAR FROM InvoiceDate) AS year,
       EXTRACT(QUARTER FROM InvoiceDate) AS quarter
   FROM staging_fact_invoice;
   ```
   - Účel: Podporuje analýzu podľa času, napr. mesačné alebo ročné trendy.

6. **fact_invoice**
   - Tabuľka `fact_invoice` spája údaje zo stagingových tabuliek `staging_fact_invoice` a `staging_fact_invoiceline` a dopĺňa ich informáciami z dimenzionálnych tabuliek `dim_date`, `dim_employee` a `dim_playlist`. Obsahuje podrobnosti o predaji vrátane jednotkovej ceny, množstva a celkovej sumy faktúry.
   - Tabuľka `fact_invoice` je centrálnou tabuľkou pre analýzu predajov a fakturácie. Umožňuje pokročilé analýzy výkonnosti produktov, zákazníkov, zamestnancov a časových trendov.
   - Primárne kľúče
      -  **fact_id**: Unikátny identifikátor faktúry. Používa sa na rozlíšenie každej faktúry.
      -  **date_id**: Dátum transakcie (odkazuje na `dim_date`). Umožňuje analýzu na základe času, napríklad denné, týždenné alebo ročné trendy.
      -  **customer_id**: Identifikátor zákazníka (odkazuje na `dim_customer`). Podporuje analýzu zákazníkov vrátane demografie a predaja podľa regiónov.
      -  **employee_id**: Identifikátor zamestnanca (odkazuje na `dim_employee`). Pomáha hodnotiť výkon zamestnancov na základe generovaných tržieb.
      -  **track_id**: Identifikátor skladby (odkazuje na `dim_track`). Podporuje analýzu predaja konkrétnych skladieb alebo žánrov.
      -  **playlist_id**: Identifikátor playlistu (odkazuje na `dim_playlist`). Identifikuje trendy alebo populárne skladby v playlistoch.
   - Metriky
      -  **unit_price**: Jednotková cena skladby alebo produktu. Používa sa na výpočet tržieb alebo priemernej ceny.
      -  **quantity**: Počet predaných položiek. Pomáha sledovať objemy predaja.
      -  **line_total**: Predpočítaný súčet pre riadok faktúry (`unit_price * quantity`). Používa sa na výpočet tržieb na úrovni skladieb.
      -  **invoice_total**: Celková suma faktúry. Používa sa na analýzu tržieb na faktúru alebo zákazníka.
   - SQL kód:
   ```sql
   CREATE OR REPLACE TABLE fact_invoice AS
   SELECT
       i.InvoiceId AS fact_id,
       i.CustomerId AS customer_id,
       e.employee_id AS employee_id,
       d.date AS date_id,
       il.TrackId AS track_id,
       pt.PlaylistId AS playlist_id,
       il.UnitPrice AS unit_price,
       il.Quantity AS quantity,
       il.UnitPrice * il.Quantity AS line_total,
       i.Total AS invoice_total
   FROM staging_fact_invoice i
   LEFT JOIN staging_fact_invoiceline il ON i.InvoiceId = il.InvoiceId
   LEFT JOIN dim_date d ON CAST(i.InvoiceDate AS DATE) = d.date
   LEFT JOIN dim_employee e ON e.employee_id = i.CustomerId
   LEFT JOIN staging_dim_playlisttrack pt ON il.TrackId = pt.TrackId;
   ```
   
### Vizualizácie
Projekt zahŕňa vizualizácie vytvorené na základe dimenzionálnych a faktových tabuliek.

1. **Top song by revenue**
   - **Popis:** Zobrazuje 10 skladieb s najvyššími tržbami na základe predaja.
   - **Vstupy:** Dimenzionálna tabuľka `dim_track`, faktová tabuľka `fact_invoice`.

```sql
SELECT 
    t.name AS track_name,
    SUM(f.line_total) AS total_revenue
FROM fact_invoice f
JOIN dim_track t ON f.track_id = t.track_id
GROUP BY t.name
ORDER BY total_revenue DESC
LIMIT 10;
```
   - **Výstup:** Stĺpcový graf, kde osi reprezentujú skladby a ich celkové tržby.
   - <img src="https://github.com/user-attachments/assets/17de46ee-13e7-431d-a341-244e3411330c" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">

2. **Transactions count by days of the week**
   - **Popis:** Počet transakcií podľa jednotlivých dní v týždni.
   - **Vstupy:** Faktová tabuľka `fact_invoice`, dimenzionálna tabuľka `dim_date`.

```sql
SELECT 
    CASE 
        WHEN d.day = 1 THEN 'Monday'
        WHEN d.day = 2 THEN 'Tuesday'
        WHEN d.day = 3 THEN 'Wednesday'
        WHEN d.day = 4 THEN 'Thursday'
        WHEN d.day = 5 THEN 'Friday'
        WHEN d.day = 6 THEN 'Saturday'
        WHEN d.day = 7 THEN 'Sunday'
    END AS day_of_week,
    COUNT(fi.fact_id) AS total_activity
FROM fact_invoice fi
JOIN dim_date d ON fi.date_id = d.date
GROUP BY d.day
ORDER BY d.day;
```
   - **Výstup:** Stĺpcový graf reprezentujúci počet transakcií v jednotlivé dni týždňa.
   = <img src="https://github.com/user-attachments/assets/05802ee0-c038-4afd-9c84-00807af92d1b" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">

3. **Best employees by revenue generated**
   - **Popis:** Zobrazuje zamestnancov zoradených podľa tržieb, ktoré generovali.
   - **Vstupy:** Dimenzionálna tabuľka `dim_employee`, faktová tabuľka `fact_invoice`.

```sql
SELECT 
    e.full_name AS employee_name,
    SUM(f.line_total) AS total_revenue
FROM fact_invoice f
JOIN dim_employee e ON f.employee_id = e.employee_id
GROUP BY e.full_name
ORDER BY total_revenue DESC;
```
   - **Výstup:** Horizontálny stĺpcový graf ukazujúci zamestnancov a ich príspevok na tržby.
   = <img src="https://github.com/user-attachments/assets/37c4c59e-6b48-49a9-a0ec-dda3840e6026" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">

4. **Artists by generated revenue**
   - **Popis:** Zobrazuje top 10 interpretov na základe ich tržieb.
   - **Vstupy:** Dimenzionálna tabuľka `dim_track`, faktová tabuľka `fact_invoice`.

```sql
SELECT 
    t.artist_name AS artist,
    SUM(f.line_total) AS total_revenue
FROM fact_invoice f
JOIN dim_track t ON f.track_id = t.track_id
GROUP BY t.artist_name
ORDER BY total_revenue DESC
LIMIT 10;
```
   - **Výstup:** Stĺpcový graf zoradený podľa interpretov a ich tržieb.
   = <img src="https://github.com/user-attachments/assets/9db3f58d-1530-4e5d-b0a7-8bd17dfbf19c" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">

5. **Countries by generated revenue**
   - **Popis:** Zobrazuje top 10 krajín podľa generovaných tržieb.
   - **Vstupy:** Dimenzionálna tabuľka `dim_customer`, faktová tabuľka `fact_invoice`.

```sql
SELECT 
    c.country,
    COUNT(f.fact_id) AS total_transactions,
    SUM(f.line_total) AS total_revenue
FROM fact_invoice f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC
LIMIT 10;
```
   - **Výstup:** Horizontálny stĺpcový graf reprezentujúci krajiny a ich podiel na tržbách.
   = <img src="https://github.com/user-attachments/assets/31cc7b11-1c7b-4db1-b32a-73ece2081b06" alt="Chinook_ERD_star_scheme" style="max-width:100%; height:auto;">



## Autor: Martin Studený
