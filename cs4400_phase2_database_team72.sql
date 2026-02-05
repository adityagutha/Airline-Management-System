-- CS4400: Introduction to Database Systems (Spring 2025)
-- Phase II: Create Table & Insert Statements [v0] Monday, February 3, 2025 @ 17:00 EST

-- Team 72
-- Vignesh Minjur vminjur3
-- Aditya Gutha agutha6
-- Yuv Rout yrout3
-- Rishi Sukumar rsukumar7

-- Directions:
-- Please follow all instructions for Phase II as listed on Canvas.
-- Fill in the team number and names and GT usernames for all members above.
-- Create Table statements must be manually written, not taken from an SQL Dump file.
-- This file must run without error for credit.

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'airline_management';
drop database if exists airline_management;
create database if not exists airline_management;
use airline_management;

-- Define the database structures
/* You must enter your tables definitions, along with your primary, unique and foreign key
declarations, and data insertion statements here.  You may sequence them in any order that
works for you.  When executed, your statements must create a functional database that contains
all of the data, and supports as many of the constraints as reasonably possible. */

-- location
CREATE TABLE Location (
    locID VARCHAR(50) PRIMARY KEY
);
-- person
CREATE TABLE Person (
    personID VARCHAR(50) PRIMARY KEY,
    first VARCHAR(100) NOT NULL,
    last VARCHAR(100) NOT NULL,
    locationID VARCHAR(50),
    FOREIGN KEY (locationID) REFERENCES Location(locID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- pilot
CREATE TABLE Pilot (
    personID VARCHAR(50) PRIMARY KEY,
    taxID VARCHAR(50) UNIQUE NOT NULL,
    experience INT NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person(personID)
        ON UPDATE RESTRICT
        ON DELETE CASCADE
);

-- pilot license
CREATE TABLE Pilot_License (
    personID VARCHAR(50),
    license VARCHAR(50) NOT NULL,
    PRIMARY KEY (personID, license),
    FOREIGN KEY (personID) REFERENCES Pilot(personID)
        ON UPDATE RESTRICT
        ON DELETE CASCADE
);

-- passenger
CREATE TABLE Passenger (
    personID VARCHAR(50) PRIMARY KEY,
    funds DECIMAL(10,2) NOT NULL,
    miles INT NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person(personID)
        ON UPDATE RESTRICT
        ON DELETE CASCADE
);

-- passenger vacatoin
CREATE TABLE Passenger_Vacation (
    personID VARCHAR(50),
    destination VARCHAR(100) NOT NULL,
    sequence INT NOT NULL,
    PRIMARY KEY (personID, destination, sequence),
    FOREIGN KEY (personID) REFERENCES Passenger(personID)
        ON UPDATE RESTRICT
        ON DELETE CASCADE
);

-- airline
CREATE TABLE Airline (
    airlineID VARCHAR(50) PRIMARY KEY,
    revenue DECIMAL(15,2) NOT NULL
);

-- airport
CREATE TABLE Airport (
    airportID VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50),
    country VARCHAR(100) NOT NULL,
    locationID VARCHAR(50),
    FOREIGN KEY (locationID) REFERENCES Location(locID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Airplane Table
CREATE TABLE Airplane (
    airlineID VARCHAR(50),
    tail_num VARCHAR(50),
    speed INT NOT NULL,
    seat_cap INT NOT NULL,
    locationID VARCHAR(50),
    PRIMARY KEY (airlineID, tail_num),
    FOREIGN KEY (airlineID) REFERENCES Airline(airlineID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (locationID) REFERENCES Location(locID)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Boeing Table
CREATE TABLE Boeing (
    airlineID VARCHAR(50),
    tail_num VARCHAR(50),
    maintained DATE NOT NULL,
    model VARCHAR(50) NOT NULL,
    PRIMARY KEY (airlineID, tail_num),
    FOREIGN KEY (airlineID, tail_num) REFERENCES Airplane(airlineID, tail_num)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Airbus Table
CREATE TABLE Airbus (
    airlineID VARCHAR(50),
    tail_num VARCHAR(50),
    variant VARCHAR(50) NOT NULL,
    PRIMARY KEY (airlineID, tail_num),
    FOREIGN KEY (airlineID, tail_num) REFERENCES Airplane(airlineID, tail_num)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Leg Table
CREATE TABLE Leg (
    legID VARCHAR(50) PRIMARY KEY,
    distance DECIMAL(10,2) NOT NULL,
    fromairport VARCHAR(50) NOT NULL,
    toairport VARCHAR(50) NOT NULL,
    FOREIGN KEY (fromairport) REFERENCES Airport(airportID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (toairport) REFERENCES Airport(airportID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- routes
CREATE TABLE Route (
    routeID VARCHAR(50) PRIMARY KEY
);

-- contains (join route + leg)
CREATE TABLE Contains (
    routeID VARCHAR(50),
    legID VARCHAR(50),
    sequence INT NOT NULL,
    PRIMARY KEY (routeID, legID),
    FOREIGN KEY (routeID) REFERENCES Route(routeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (legID) REFERENCES Leg(legID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Flight table
CREATE TABLE Flight (
    flightID VARCHAR(50) PRIMARY KEY,
    cost DECIMAL(10,2) NOT NULL,
    routeID VARCHAR(50),
    pilotID VARCHAR(50),
    FOREIGN KEY (routeID) REFERENCES Route(routeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (pilotID) REFERENCES Pilot(taxID)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Supports Table
CREATE TABLE Supports (
    flightID VARCHAR(50),
    airlineID VARCHAR(50),
    tail_num VARCHAR(50),
    progress DECIMAL(5,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    next_time TIME,
    PRIMARY KEY (flightID, airlineID, tail_num),
    FOREIGN KEY (flightID) REFERENCES Flight(flightID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (airlineID, tail_num) REFERENCES Airplane(airlineID, tail_num)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- INSERT STATEMENTS

INSERT INTO Location (locID) VALUES
('port_1'),
('port_2'),
('port_3'),
('port_4'),
('port_6'),
('port_7'),
('port_10'),
('port_11'),
('port_12'),
('port_13'),
('port_14'),
('port_15'),
('port_16'),
('port_17'),
('port_18'),
('port_20'),
('port_21'),
('port_22'),
('port_23'),
('port_24'),
('port_25'),
('plane_1'),
('plane_2'),
('plane_3'),
('plane_4'),
('plane_5'),
('plane_6'),
('plane_7'),
('plane_8'),
('plane_10'),
('plane_13'),
('plane_18'),
('plane_20');

INSERT INTO Person (personID, first, last, locationID) VALUES
('p1',  'Jeanne',    'Nelson',   'port_1'),
('p2',  'Roxanne',   'Byrd',     'port_1'),
('p11', 'Sandra',    'Cruz',     'port_3'),
('p13', 'Bryant',    'Figueroa', 'port_3'),
('p14', 'Dana',      'Perry',    'port_3'),
('p15', 'Matt',      'Hunt',     'port_10'),
('p16', 'Edna',      'Brown',    'port_10'),
('p12', 'Dan',       'Ball',     'port_3'),
('p17', 'Ruby',      'Burgess',  'plane_3'),
('p18', 'Esther',    'Pittman',  'plane_10'),
('p19', 'Doug',      'Fowler',   'port_17'),
('p8',  'Bennie',    'Palmer',   'port_2'),
('p20', 'Thomas',    'Olson',    'port_17'),
('p21', 'Mona',      'Harrison', 'plane_1'),
('p22', 'Arlene',    'Massey',   'plane_1'),
('p23', 'Judith',    'Patrick',  'plane_1'),
('p24', 'Reginald',  'Rhodes',   'plane_5'),
('p25', 'Vincent',   'Garcia',   'plane_5'),
('p26', 'Cheryl',    'Moore',    'plane_5'),
('p27', 'Michael',   'Rivera',   'plane_8'),
('p28', 'Luther',    'Matthews', 'plane_8'),
('p29', 'Moses',     'Parks',    'plane_13'),
('p3',  'Tanya',     'Nguyen',   'port_1'),
('p30', 'Ora',       'Steele',   'plane_13'),
('p31', 'Antonio',   'Flores',   'plane_13'),
('p32', 'Glenn',     'Ross',     'plane_13'),
('p33', 'Irma',      'Thomas',   'plane_20'),
('p34', 'Ann',       'Maldonado','plane_20'),
('p35', 'Jeffrey',   'Cruz',     'port_12'),
('p36', 'Sonya',     'Price',    'port_12'),
('p37', 'Tracy',     'Hale',     'port_12'),
('p38', 'Albert',    'Simmons',  'port_14'),
('p39', 'Karen',     'Terry',    'port_15'),
('p4',  'Kendra',    'Jacobs',   'port_1'),
('p40', 'Glen',      'Kelley',   'plane_20'),
('p41', 'Brooke',    'Little',   'port_3'),
('p42', 'Daryl',     'Nguyen',   'port_4'),
('p43', 'Judy',      'Willis',   'port_14'),
('p44', 'Marco',     'Klein',    'port_15'),
('p45', 'Angelica',  'Hampton',  'port_16'),
('p5',  'Jeff',      'Burton',   'port_1'),
('p6',  'Randal',    'Parks',    'port_1'),
('p10', 'Lawrence',  'Morgan',   'port_3'),
('p7',  'Sonya',     'Owens',    'port_2'),
('p9',  'Marlene',   'Warner',   'port_3'),
('p46', 'Janice',    'White',    'plane_10');


INSERT INTO Airline (airlineID, revenue) VALUES
('Delta', 53000),
('United', 48000),
('British Airways', 24000),
('Lufthansa', 35000),
('Air_France', 29000),
('KLM', 29000),
('Ryanair', 10000),
('Japan Airlines', 9000),
('China Southern Airlines', 14000),
('Korean Air Lines', 10000),
('American', 52000);


INSERT INTO Airport (airportID, name, city, state, country, locationID) VALUES
('ATL', 'Atlanta Hartsfield_Jackson International', 'Atlanta', 'Georgia', 'USA', 'port_1'),
('DXB', 'Dubai International', 'Dubai', 'Al Garhoud', 'UAE', 'port_2'),
('HND', 'Tokyo International Haneda', 'Ota City', 'Tokyo', 'JPN', 'port_3'),
('LHR', 'London Heathrow', 'London', 'England', 'GBR', 'port_4'),
('IST', 'Istanbul International', 'Arnavutkoy', 'Istanbul', 'TUR', NULL),
('DFW', 'Dallas_Fort Worth International', 'Dallas', 'Texas', 'USA', 'port_6'),
('CAN', 'Guangzhou International', 'Guangzhou', 'Guangdong', 'CHN', 'port_7'),
('DEN', 'Denver International', 'Denver', 'Colorado', 'USA', NULL),
('LAX', 'Los Angeles International', 'Los Angeles', 'California', 'USA', NULL),
('ORD', 'O_Hare International', 'Chicago', 'Illinois', 'USA', 'port_10'),
('AMS', 'Amsterdam Schipol International', 'Amsterdam', 'Haarlemmermeer', 'NLD', 'port_11'),
('CDG', 'Paris Charles de Gaulle', 'Roissy_en_France', 'Paris', 'FRA', 'port_12'),
('FRA', 'Frankfurt International', 'Frankfurt', 'Frankfurt_Rhine_Main', 'DEU', 'port_13'),
('MAD', 'Madrid Adolfo Suarez_Barajas', 'Madrid', 'Barajas', 'ESP', 'port_14'),
('BCN', 'Barcelona International', 'Barcelona', 'Catalonia', 'ESP', 'port_15'),
('FCO', 'Rome Fiumicino', 'Fiumicino', 'Lazio', 'ITA', 'port_16'),
('LGW', 'London Gatwick', 'London', 'England', 'GBR', 'port_17'),
('MUC', 'Munich International', 'Munich', 'Bavaria', 'DEU', 'port_18'),
('MDW', 'Chicago Midway International', 'Chicago', 'Illinois', 'USA', NULL),
('IAH', 'George Bush Intercontinental', 'Houston', 'Texas', 'USA', 'port_20'),
('HOU', 'William P_Hobby International', 'Houston', 'Texas', 'USA', 'port_21'),
('NRT', 'Narita International', 'Narita', 'Chiba', 'JPN', 'port_22'),
('BER', 'Berlin Brandenburg Willy Brandt International', 'Berlin', 'Schonefeld', 'DEU', 'port_23'),
('ICN', 'Incheon International Airport', 'Seoul', 'Jung_gu', 'KOR', 'port_24'),
('PVG', 'Shanghai Pudong International Airport', 'Shanghai', 'Pudong', 'CHN', 'port_25');


INSERT INTO Airplane (airlineID, tail_num, speed, seat_cap, locationID) VALUES
('Delta', 'n106js', 800, 4, 'plane_1'),
('Delta', 'n110jn', 800, 5, NULL),
('Delta', 'n127js', 600, 4, 'plane_3'),
('United', 'n330ss', 800, 4, 'plane_4'),
('United', 'n380sd', 400, 5, 'plane_5'),
('British Airways', 'n616lt', 600, 7, 'plane_6'),
('British Airways', 'n517ly', 600, 4, 'plane_7'),
('Lufthansa', 'n620la', 800, 4, 'plane_8'),
('Lufthansa', 'n401fj', 300, 4, NULL),
('Lufthansa', 'n653fk', 600, 6, 'plane_10'),
('Air_France', 'n118fm', 400, 4, NULL),
('Air_France', 'n815pw', 400, 3, NULL),
('KLM', 'n161fk', 600, 4, 'plane_13'),
('KLM', 'n337as', 400, 5, NULL),
('KLM', 'n256ap', 300, 4, NULL),
('Ryanair', 'n156sq', 600, 8, NULL),
('Ryanair', 'n451fi', 600, 5, NULL),
('Ryanair', 'n341eb', 400, 4, 'plane_18'),
('Ryanair', 'n353kz', 400, 4, NULL),
('Japan Airlines', 'n305fv', 400, 6, 'plane_20'),
('Japan Airlines', 'n443wu', 800, 4, NULL),
('China Southern Airlines', 'n454gq', 400, 3, NULL),
('China Southern Airlines', 'n249yk', 400, 4, NULL),
('Korean Air Lines', 'n180co', 600, 5, NULL),
('American', 'n448cs', 400, 4, NULL),
('American', 'n225sb', 800, 8, 'plane_2'),
('American', 'n553qn', 800, 5, NULL);

INSERT INTO Boeing (airlineID, tail_num, maintained, model) VALUES
('United', 'n330ss', '2024-01-01', '777'),
('KLM', 'n337as', '2024-01-01', '737'),
('Ryanair', 'n341eb', '2024-01-01', '737'),
('Ryanair', 'n451fi', '2024-01-01', '737'),
('Japan Airlines', 'n443wu', '2024-01-01', '787'),
('China Southern Airlines', 'n249yk', '2024-01-01', '787');

INSERT INTO Airbus (airlineID, tail_num, variant) VALUES
('Delta', 'n106js', 'FALSE'),
('Delta', 'n127js', 'FALSE'),
('Delta', 'n110jn', 'TRUE'),
('United', 'n380sd', 'FALSE'),
('British Airways', 'n616lt', 'FALSE'),
('British Airways', 'n517ly', 'FALSE'),
('Lufthansa', 'n620la', 'FALSE'),
('Lufthansa', 'n401fj', 'TRUE'),
('Lufthansa', 'n653fk', 'FALSE'),
('Air_France', 'n118fm', 'FALSE'),
('Air_France', 'n815pw', 'TRUE'),
('KLM', 'n161fk', 'FALSE'),
('KLM', 'n256ap', 'FALSE'),
('Ryanair', 'n156sq', 'FALSE'),
('Ryanair', 'n353kz', 'TRUE'),
('Japan Airlines', 'n305fv', 'FALSE'),
('China Southern Airlines', 'n454gq', 'FALSE'),
('Korean Air Lines', 'n180co', 'FALSE'),
('American', 'n448cs', 'FALSE'),
('American', 'n553qn', 'FALSE'),
('American', 'n225sb', 'FALSE');

INSERT INTO Pilot (personID, taxID, experience) VALUES
('p1', '330-12-6907', 31),
('p2', '842-88-1257', 9),
('p3', '750-24-7616', 11),
('p4', '776-21-8098', 24),
('p5', '933-93-2165', 27),
('p6', '707-84-4555', 38),
('p10', '769-60-1266', 15),
('p7', '450-25-5617', 13),
('p9', '936-44-6941', 13),
('p11', '369-22-9505', 22),
('p12', '680-92-5329', 24),
('p13', '513-40-4168', 24),
('p14', '454-71-7847', 13),
('p15', '153-47-8101', 30),
('p16', '598-47-5172', 28),
('p18', '250-86-2784', 23),
('p19', '386-39-7881', 2),
('p8', '701-38-2179', 12),
('p20', '522-44-3098', 28);

INSERT INTO Pilot_License (personID, license) VALUES
('p1', 'airbus'),
('p2', 'airbus'),
('p2', 'boeing'),
('p3', 'airbus'),
('p4', 'airbus'),
('p4', 'boeing'),
('p5', 'airbus'),
('p6', 'airbus'),
('p6', 'boeing'),
('p10', 'airbus'),
('p7', 'airbus'),
('p9', 'airbus'),
('p9', 'boeing'),
('p9', 'general'),
('p11', 'airbus'),
('p11', 'boeing'),
('p12', 'boeing'),
('p13', 'airbus'),
('p14', 'airbus'),
('p15', 'airbus'),
('p15', 'boeing'),
('p15', 'general'),
('p16', 'airbus'),
('p18', 'airbus'),
('p19', 'airbus'),
('p8', 'boeing'),
('p20', 'airbus');

INSERT INTO Passenger (personID, funds, miles) VALUES
('p21', 700, 771),
('p22', 200, 374),
('p23', 400, 414),
('p24', 500, 292),
('p25', 300, 390),
('p26', 600, 302),
('p27', 400, 470),
('p28', 400, 208),
('p29', 700, 292),
('p30', 500, 686),
('p31', 400, 547),
('p32', 500, 257),
('p33', 600, 564),
('p34', 200, 211),
('p35', 500, 233),
('p36', 400, 293),
('p37', 700, 552),
('p38', 700, 812),
('p39', 400, 541),
('p40', 700, 441),
('p41', 300, 875),
('p42', 500, 691),
('p43', 300, 572),
('p44', 500, 572),
('p45', 500, 663),
('p46', 5000, 690);

INSERT INTO Passenger_Vacation (personID, destination, sequence) VALUES
('p21', 'AMS', 1),
('p22', 'AMS', 1),
('p23', 'BER', 1),
('p24', 'MUC', 1),
('p24', 'CDG', 2),
('p25', 'MUC', 1),
('p26', 'MUC', 1),
('p27', 'BER', 1),
('p28', 'LGW', 1),
('p29', 'FCO', 1),
('p29', 'LHR', 2),
('p30', 'FCO', 1),
('p30', 'MAD', 2),
('p31', 'FCO', 1),
('p32', 'FCO', 1),
('p33', 'CAN', 1),
('p34', 'HND', 1),
('p35', 'LGW', 1),
('p36', 'FCO', 1),
('p37', 'FCO', 1),
('p37', 'LGW', 2),
('p37', 'CDG', 3),
('p38', 'MUC', 1),
('p39', 'MUC', 1),
('p46', 'LGW', 1);

INSERT INTO Leg (legID, distance, fromairport, toairport) VALUES
('leg_1', 400, 'AMS', 'BER'),
('leg_2', 3900, 'ATL', 'AMS'),
('leg_3', 3700, 'ATL', 'LHR'),
('leg_4', 600, 'ATL', 'ORD'),
('leg_5', 500, 'BCN', 'CDG'),
('leg_6', 300, 'BCN', 'MAD'),
('leg_7', 4700, 'BER', 'CAN'),
('leg_8', 600, 'BER', 'LGW'),
('leg_9', 300, 'BER', 'MUC'),
('leg_10', 1600, 'CAN', 'HND'),
('leg_11', 500, 'CDG', 'BCN'),
('leg_12', 500, 'CDG', 'BCN'),
('leg_14', 400, 'CDG', 'MUC'),
('leg_15', 200, 'DFW', 'IAH'),
('leg_16', 800, 'FCO', 'MAD'),
('leg_17', 300, 'FRA', 'BER'),
('leg_18', 100, 'HND', 'NRT'),
('leg_19', 300, 'HOU', 'DFW'),
('leg_20', 100, 'IAH', 'HOU'),
('leg_21', 600, 'LGW', 'BER'),
('leg_22', 600, 'LHR', 'BER'),
('leg_23', 500, 'LHR', 'MUC'),
('leg_24', 300, 'MAD', 'BCN'),
('leg_25', 800, 'MAD', 'FCO'),
('leg_26', 800, 'MAD', 'FCO'),
('leg_27', 300, 'MUC', 'BER'),
('leg_28', 400, 'MUC', 'CDG'),
('leg_29', 400, 'MUC', 'FCO'),
('leg_30', 200, 'MUC', 'FRA'),
('leg_31', 3700, 'ORD', 'CDG'),
('leg_32', 6800, 'DFW', 'ICN'),
('leg_33', 4400, 'ICN', 'LHR'),
('leg_34', 5900, 'ICN', 'LAX'),
('leg_35', 3700, 'CDG', 'ORD'),
('leg_36', 100, 'NRT', 'HND'),
('leg_37', 500, 'PVG', 'ICN'),
('leg_38', 6500, 'LAX', 'PVG');

INSERT INTO Route (routeID) VALUES
('americas_hub_exchange'),
('americas_one'),
('americas_three'),
('americas_two'),
('big_europe_loop'),
('euro_north'),
('euro_south'),
('germany_local'),
('pacific_rim_tour'),
('south_euro_loop'),
('texas_local'),
('korea_direct');

-- contains data (leg + route)
INSERT INTO Contains (routeID, legID, sequence) VALUES
('americas_hub_exchange', 'leg_4', 1),
('americas_one', 'leg_2', 1),
('americas_one', 'leg_1', 2),
('americas_three', 'leg_31', 1),
('americas_three', 'leg_14', 2),
('americas_two', 'leg_3', 1),
('americas_two', 'leg_22', 2),
('big_europe_loop', 'leg_23', 1),
('big_europe_loop', 'leg_29', 2),
('big_europe_loop', 'leg_16', 3),
('euro_north', 'leg_16', 1),
('euro_north', 'leg_24', 2),
('euro_north', 'leg_5', 3),
('euro_north', 'leg_14', 4),
('euro_north', 'leg_27', 5),
('euro_north', 'leg_8', 6),
('euro_south', 'leg_21', 1),
('euro_south', 'leg_9', 2),
('euro_south', 'leg_28', 3),
('euro_south', 'leg_11', 4),
('euro_south', 'leg_6', 5),
('euro_south', 'leg_26', 6),
('germany_local', 'leg_9', 1),
('germany_local', 'leg_30', 2),
('germany_local', 'leg_17', 3),
('pacific_rim_tour', 'leg_7', 1),
('pacific_rim_tour', 'leg_10', 2),
('pacific_rim_tour', 'leg_18', 3),
('south_euro_loop', 'leg_16', 1),
('south_euro_loop', 'leg_24', 2),
('south_euro_loop', 'leg_5', 3),
('south_euro_loop', 'leg_12', 4),
('texas_local', 'leg_15', 1),
('texas_local', 'leg_20', 2),
('texas_local', 'leg_19', 3),
('korea_direct', 'leg_32', 1);

-- flight data
INSERT INTO Flight (flightID, cost, routeID, pilotID) VALUES
('dl_10', 200, 'americas_one', '330-12-6907'),
('un_38', 200, 'americas_three', '776-21-8098'),
('ba_61', 200, 'americas_two', '933-93-2165'),
('lf_20', 300, 'euro_north', '769-60-1266'),
('km_16', 400, 'euro_south', '750-24-7616'),
('ba_51', 100, 'big_europe_loop', '707-84-4555'),
('ja_35', 300, 'pacific_rim_tour', '153-47-8101'),
('ry_34', 100, 'germany_local', '701-38-2179'),
('aa_12', 150, 'americas_hub_exchange', '936-44-6941'),
('dl_42', 220, 'americas_one', '842-88-1257'),
('ke_64', 500, 'korea_direct', NULL),
('lf_67', 900, 'euro_north', '250-86-2784');

-- support
INSERT INTO Supports (flightID, airlineID, tail_num, progress, status, next_time) VALUES
('dl_10', 'Delta', 'n106js', 1, 'in_flight', '08:00:00'),
('un_38', 'United', 'n380sd', 2, 'in_flight', '14:30:00'),
('ba_61', 'British Airways', 'n616lt', 0, 'on_ground', '09:30:00'),
('lf_20', 'Lufthansa', 'n620la', 3, 'in_flight', '11:00:00'),
('km_16', 'KLM', 'n161fk', 6, 'in_flight', '14:00:00'),
('ba_51', 'British Airways', 'n517ly', 0, 'on_ground', '11:30:00'),
('ja_35', 'Japan Airlines', 'n305fv', 1, 'in_flight', '09:30:00'),
('ry_34', 'Ryanair', 'n341eb', 0, 'on_ground', '15:00:00'),
('aa_12', 'American', 'n553qn', 1, 'on_ground', '12:15:00'),
('dl_42', 'Delta', 'n110jn', 0, 'on_ground', '13:45:00'),
('ke_64', 'Korean Air Lines', 'n180co', 0, 'on_ground', '16:00:00'),
('lf_67', 'Lufthansa', 'n653fk', 6, 'on_ground', '21:23:00');