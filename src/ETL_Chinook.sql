// Create the database and schema
CREATE DATABASE IF NOT EXISTS FALCON_CHINOOK;
USE DATABASE FALCON_CHINOOK;

CREATE SCHEMA IF NOT EXISTS FALCON_SCHEME;
USE SCHEMA FALCON_SCHEME;


/*LIST @FALCON_CHINOOK_DATA;
SHOW TABLES IN SCHEMA FALCON_SCHEME;*/

// Create staging tables (11 staging tables)

// Genre
CREATE TABLE IF NOT EXISTS staging_dim_genre (
    GenreId INT PRIMARY KEY,
    Name VARCHAR(120)
);

// MediaType
CREATE TABLE IF NOT EXISTS staging_dim_mediatype (
    MediaTypeId INT PRIMARY KEY,
    Name VARCHAR(120)
);

// Artist
CREATE TABLE IF NOT EXISTS staging_dim_artist (
    ArtistId INT PRIMARY KEY,
    Name VARCHAR(120)
);

// Album
CREATE TABLE IF NOT EXISTS staging_dim_album (
    AlbumId INT PRIMARY KEY,
    Title VARCHAR(160),
    ArtistId INT,
    FOREIGN KEY (ArtistId) REFERENCES staging_dim_artist(ArtistId)
);

// Track
CREATE TABLE IF NOT EXISTS staging_dim_track (
    TrackId INT PRIMARY KEY,
    Name VARCHAR(200),
    AlbumId INT,
    MediaTypeId INT,
    GenreId INT,
    Composer VARCHAR(220),
    Milliseconds INT,
    Bytes INT,
    UnitPrice DECIMAL(10, 2),
    FOREIGN KEY (AlbumId) REFERENCES staging_dim_album(AlbumId),
    FOREIGN KEY (MediaTypeId) REFERENCES staging_dim_mediatype(MediaTypeId),
    FOREIGN KEY (GenreId) REFERENCES staging_dim_genre(GenreId)
);

// Customer
CREATE TABLE IF NOT EXISTS staging_dim_customer (
    CustomerId INT PRIMARY KEY,
    FirstName VARCHAR(40),
    LastName VARCHAR(40),
    Company VARCHAR(80),
    Address VARCHAR(100),
    City VARCHAR(50),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(20),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    SupportRepId INT
);

// Employee
CREATE TABLE IF NOT EXISTS staging_dim_employee (
    EmployeeId INT PRIMARY KEY,
    LastName VARCHAR(20),
    FirstName VARCHAR(20),
    Title VARCHAR(30),
    ReportsTo INT,
    BirthDate DATE,
    HireDate DATE,
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60)
);

// Playlist
CREATE TABLE IF NOT EXISTS staging_dim_playlist (
    PlaylistId INT PRIMARY KEY,
    Name VARCHAR(120)
);

// PlaylistTrack
CREATE TABLE IF NOT EXISTS staging_dim_playlisttrack (
    PlaylistId INT,
    TrackId INT,
    PRIMARY KEY (PlaylistId, TrackId),
    FOREIGN KEY (PlaylistId) REFERENCES staging_dim_playlist(PlaylistId),
    FOREIGN KEY (TrackId) REFERENCES staging_dim_track(TrackId)
);

// Invoice
CREATE TABLE IF NOT EXISTS staging_fact_invoice (
    InvoiceId INT PRIMARY KEY,
    CustomerId INT,
    InvoiceDate DATE,
    BillingAddress VARCHAR(70),
    BillingCity VARCHAR(40),
    BillingState VARCHAR(40),
    BillingCountry VARCHAR(40),
    BillingPostalCode VARCHAR(10),
    Total DECIMAL(10, 2),
    FOREIGN KEY (CustomerId) REFERENCES staging_dim_customer(CustomerId)
);

// InvoiceLine
CREATE TABLE IF NOT EXISTS staging_fact_invoiceline (
    InvoiceLineId INT PRIMARY KEY,
    InvoiceId INT,
    TrackId INT,
    UnitPrice DECIMAL(10, 2),
    Quantity INT,
    FOREIGN KEY (InvoiceId) REFERENCES staging_fact_invoice(InvoiceId),
    FOREIGN KEY (TrackId) REFERENCES staging_dim_track(TrackId)
);

// Load data into staging tables

CREATE OR REPLACE STAGE FALCON_CHINOOK_DATA;

COPY INTO staging_dim_artist
FROM @FALCON_CHINOOK_DATA/chinook_table_artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_customer
FROM @FALCON_CHINOOK_DATA/chinook_table_customer.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_album
FROM @FALCON_CHINOOK_DATA/chinook_table_album.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_track
FROM @FALCON_CHINOOK_DATA/chinook_table_track.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_employee
FROM @FALCON_CHINOOK_DATA/chinook_table_employee.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = ('NULL', ''));

COPY INTO staging_dim_playlist
FROM @FALCON_CHINOOK_DATA/chinook_table_playlist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_playlisttrack
FROM @FALCON_CHINOOK_DATA/chinook_table_playlisttrack.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_genre
FROM @FALCON_CHINOOK_DATA/chinook_table_genre.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_dim_mediatype
FROM @FALCON_CHINOOK_DATA/chinook_table_mediatype.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_fact_invoice
FROM @FALCON_CHINOOK_DATA/chinook_table_invoice.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO staging_fact_invoiceline
FROM @FALCON_CHINOOK_DATA/chinook_table_invoiceline.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

/*SELECT 'staging_dim_artist' AS table_name, COUNT(*) AS row_count FROM staging_dim_artist
UNION ALL
SELECT 'staging_dim_customer', COUNT(*) FROM staging_dim_customer
UNION ALL
SELECT 'staging_dim_album', COUNT(*) FROM staging_dim_album
UNION ALL
SELECT 'staging_dim_track', COUNT(*) FROM staging_dim_track
UNION ALL
SELECT 'staging_dim_employee', COUNT(*) FROM staging_dim_employee
UNION ALL
SELECT 'staging_dim_playlist', COUNT(*) FROM staging_dim_playlist
UNION ALL
SELECT 'staging_dim_playlisttrack', COUNT(*) FROM staging_dim_playlisttrack
UNION ALL
SELECT 'staging_dim_genre', COUNT(*) FROM staging_dim_genre
UNION ALL
SELECT 'staging_dim_mediatype', COUNT(*) FROM staging_dim_mediatype
UNION ALL
SELECT 'staging_fact_invoice', COUNT(*) FROM staging_fact_invoice
UNION ALL
SELECT 'staging_fact_invoiceline', COUNT(*) FROM staging_fact_invoiceline;*/

// Create final dim and fact tables

// Customer Dimension
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

// Track Dimension
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

// Employee Dimension
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

// Playlist Dimension
CREATE OR REPLACE TABLE dim_playlist AS
SELECT 
    PlaylistId AS playlist_id,
    Name AS name
FROM staging_dim_playlist;

// Date Dimension
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT 
    CAST(InvoiceDate AS DATE) AS date,
    EXTRACT(DAY FROM InvoiceDate) AS day,
    EXTRACT(MONTH FROM InvoiceDate) AS month,
    EXTRACT(YEAR FROM InvoiceDate) AS year,
    EXTRACT(QUARTER FROM InvoiceDate) AS quarter
FROM staging_fact_invoice;

// Fact Table
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

/*SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dim_customer
UNION ALL
SELECT 'dim_track', COUNT(*) AS row_count FROM dim_track
UNION ALL
SELECT 'dim_employee', COUNT(*) AS row_count FROM dim_employee
UNION ALL
SELECT 'dim_playlist', COUNT(*) AS row_count FROM dim_playlist
UNION ALL
SELECT 'dim_date', COUNT(*) AS row_count FROM dim_date
UNION ALL
SELECT 'fact_invoice', COUNT(*) AS row_count FROM fact_invoice;

SELECT COUNT(DISTINCT CAST(InvoiceDate AS DATE)) AS unique_dates FROM staging_fact_invoice;

SELECT COUNT(*) AS total_lines FROM staging_fact_invoiceline;*/