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