# Falcon Chinook ETL Project

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
Stagingové tabuľky slúžia ako medzivrstva pre surové údaje. Projekt zahŕňa nasledujúce stagingové tabuľky:

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

### Dimenzionálne a faktové tabuľky

#### Dimenzionálne tabuľky

1. **dim_customer**
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

#### Faktová tabuľka

1. **fact_invoice**
   - Transformácia:
     - Spája údaje zo stagingových tabuliek `staging_fact_invoice` a `staging_fact_invoiceline`.
     - Pridáva informácie z dimenzionálnych tabuliek `dim_date`, `dim_employee` a `dim_playlist`.
     - Obsahuje podrobnosti o predaji, ako je jednotková cena, množstvo a celková suma.
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
    i.Total AS total
FROM staging_fact_invoice i
LEFT JOIN staging_fact_invoiceline il ON i.InvoiceId = il.InvoiceId
LEFT JOIN dim_date d ON CAST(i.InvoiceDate AS DATE) = d.date
LEFT JOIN dim_employee e ON e.employee_id = i.CustomerId
LEFT JOIN staging_dim_playlisttrack pt ON il.TrackId = pt.TrackId;
```
   - Účel: Táto tabuľka je centrálnou tabuľkou pre analýzu predajov a fakturácie.

### Načítanie údajov
Údaje sa načítavajú do stagingových tabuliek pomocou príkazu `COPY INTO`. Predpokladá sa, že CSV súbory sú prítomné v Snowflake stage `FALCON_CHINOOK_DATA`.

Príklad príkazu:
```sql
COPY INTO staging_dim_artist
FROM @FALCON_CHINOOK_DATA/chinook_table_artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```
