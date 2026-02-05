-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like the model and the engine.  
Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50), in ip_neo boolean)
sp_main: begin
    IF NOT EXISTS (select 1 FROM airline WHERE airlineID = ip_airlineID) THEN select 'Airline Does Not Exist' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    IF EXISTS (select 1 FROM location WHERE locationID = ip_locationID) THEN select 'Location ID is NOT UNIQUE' AS ErrorMessage;
		LEAVE sp_main; 
	END IF;
    IF EXISTS (select 1 FROM airplane WHERE airlineID = ip_airlineID AND tail_num = ip_tail_num) THEN select 'Existing Tail Number For This Airline' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    IF ip_seat_capacity <= 0 OR ip_speed <= 0 THEN select 'Seat capacity and Speed Must Be > Than Zero' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    INSERT INTO location (locationID) VALUES (ip_locationID);
	INSERT INTO airplane (airlineID, tail_num, seat_capacity, speed, locationID, plane_type, maintenanced, model, neo) VALUES (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID , ip_plane_type, 
        ip_maintenanced, ip_model, ip_neo);
END //
DELIMITER ;


-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport. A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings. An airport may have a longer, more
descriptive name. An airport must also have a city, state, and country
designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200), 
in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin
    if exists (select 1 from airport where airportID = ip_airportID) then select 'Airport ID Already Exists' as ErrorMessage;
        leave sp_main;
    end if;
    IF EXISTS (select 1 FROM location WHERE locationID = ip_locationID) THEN select 'Location ID IS NOT Unique' AS ErrorMessage;
		LEAVE sp_main;
	END IF;
    INSERT INTO location (locationID) VALUES (ip_locationID);
    insert into airport (airportID, airport_name, city, state, country, locationID) values (ip_airportID, ip_airport_name, ip_city, ip_state, ip_country, ip_locationID);
end //
delimiter ;


-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person. A new person must reference a
unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time. A person must have a first name, and might also have a last name.
A person can hold a pilot role or a passenger role (exclusively). As a pilot,
a person must have a tax identifier to receive pay, and an experience level. As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin
    IF NOT EXISTS (select 1 FROM location WHERE locationID = ip_locationID) THEN select 'Location ID Does Not Exist' AS ErrorMessage;
		LEAVE sp_main;
	END IF;
    IF EXISTS (select 1 FROM Person WHERE personID = ip_personID) THEN select 'Person ID Already Exists' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    IF NOT ((ip_experience is NULL and ip_taxID is NULL) and (ip_miles is not NULL and ip_funds is not NULL) or
		 ((ip_experience is not NULL and ip_taxID is not NULL) and (ip_miles is NULL and ip_funds is NULL))) THEN select 'Person is Not Pilot or Passegner' as ErrorMessage;
            LEAVE sp_main;
	END IF;
	INSERT INTO Person (personID, first_name, last_name, locationID)
	VALUES (ip_personID, ip_first_name, ip_last_name, ip_locationID);
    IF ip_experience is not NULL and ip_taxID is not NULL THEN INSERT INTO Pilot (personID, taxID, experience)
		VALUES (ip_personID, ip_taxID, ip_experience);
    ELSE
		INSERT INTO Passenger (personID, miles, funds)
		VALUES (ip_personID, ip_miles, ip_funds);
    END IF;
END //
DELIMITER ;


-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it aready exists, then it must be removed. */
-- -----------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS grant_or_revoke_pilot_license;
DELIMITER //

CREATE PROCEDURE grant_or_revoke_pilot_license (
    IN ip_personID VARCHAR(50),
    IN ip_license VARCHAR(100)
)
sp_main: BEGIN
    IF NOT EXISTS (select 1 FROM pilot WHERE personID = ip_personID
    ) THEN
        LEAVE sp_main;
    END IF;
    IF EXISTS (
        select 1 FROM pilot_licenses WHERE personID = ip_personID AND license = ip_license
    ) THEN DELETE FROM pilot_licenses WHERE personID = ip_personID AND license = ip_license;
    ELSE INSERT INTO pilot_licenses (personID, license)
        VALUES (ip_personID, ip_license);
    END IF;
END //
DELIMITER ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS offer_flight;
DELIMITER //

CREATE PROCEDURE offer_flight (
    IN ip_flightID VARCHAR(50), 
    IN ip_routeID VARCHAR(50),
    IN ip_support_airline VARCHAR(50), 
    IN ip_support_tail VARCHAR(50), 
    IN ip_progress INTEGER,
    IN ip_next_time TIME, 
    IN ip_cost INTEGER
)
sp_main: BEGIN
    DECLARE v_count INT;
    select count(*) INTO v_count 
    FROM route 
    WHERE routeID = ip_routeID;
    
    IF v_count = 0 THEN select 'Route Does Not Exist' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    select count(*) INTO v_count FROM airplane WHERE airlineID = ip_support_airline AND tail_num = ip_support_tail;
    
    IF v_count = 0 THEN select 'Airplane Does Not Exist' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    select count(*) INTO v_count FROM flight WHERE support_airline = ip_support_airline AND support_tail = ip_support_tail AND airplane_status = 'in_flight';
    
    IF v_count > 0 THEN select 'Airplane Already In Use' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    INSERT INTO flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time, cost) VALUES (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);
END //
DELIMITER ;


-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route. The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel. Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin
    DECLARE v_pilotID VARCHAR(50);
    DECLARE v_locID varchar(50);
    DECLARE v_mile integer;
    IF NOT EXISTS (select 1 FROM flight WHERE flightID = ip_flightID) THEN select 'Flight Does Not Exist' AS ErrorMessage;
        LEAVE sp_main;
	END IF;
    IF 'in_flight' != (select airplane_status FROM flight WHERE flightID = ip_flightID) THEN select 'Flight Not In Air' AS ErrorMessage;
        LEAVE sp_main;
	END IF;
    select locationID INTO v_locID FROM airplane WHERE tail_num = (select support_tail FROM flight WHERE flightID = ip_flightID);
    UPDATE Pilot SET experience = experience + 1 WHERE commanding_flight = ip_flightID;
    select distance INTO v_mile FROM leg l JOIN route_path r ON l.legID = r.legID JOIN flight f ON f.routeID = r.routeID
    WHERE f.flightID = ip_flightID and f.progress = r.sequence; UPDATE passenger pass JOIN person p ON pass.personID = p.personID
    SET pass.miles = pass.miles + v_mile WHERE p.locationID = v_locID; UPDATE flight SET airplane_status = 'on_ground' WHERE flightID = ip_flightID;
   UPDATE flight SET next_time = ADDTIME(next_time, '01:00:00') WHERE flightID = ip_flightID;
END //
DELIMITER ;


-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that Airbus and general planes have at least one pilot
assigned, while Boeing must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS flight_takeoff;
DELIMITER //

CREATE PROCEDURE flight_takeoff (
    IN ip_flightID VARCHAR(50)
)
sp_main: BEGIN
    DECLARE v_routeID VARCHAR(50);
    DECLARE v_progress INT;
    DECLARE v_airplane_status VARCHAR(20);
    DECLARE v_airlineID VARCHAR(50);
    DECLARE v_plane_type VARCHAR(100);
    DECLARE v_speed INT;
	DECLARE v_tail_num VARCHAR(50);
    DECLARE v_pilot_count INT;
    DECLARE v_leg_distance INT;
    DECLARE v_next_leg VARCHAR(50);
    DECLARE v_current_airport CHAR(3);
    DECLARE v_next_airport CHAR(3);
    DECLARE v_flight_time TIME;
    IF NOT EXISTS (
        select 1 FROM Flight WHERE flightID = ip_flightID) THEN LEAVE sp_main; END IF;

    select routeID, progress, airplane_status, support_airline, support_tail INTO v_routeID, v_progress, v_airplane_status, v_airlineID, v_tail_num
    FROM Flight WHERE flightID = ip_flightID;
IF v_airplane_status != 'on_ground' THEN LEAVE sp_main; END IF;
    select COUNT(*) INTO v_pilot_count FROM Route_path WHERE routeID = v_routeID AND sequence > v_progress;
    IF v_pilot_count = 0 THEN LEAVE sp_main; END IF;
    select plane_type, speed INTO v_plane_type, v_speed FROM Airplane
    WHERE airlineID = v_airlineID AND tail_num = v_tail_num;
    select COUNT(*) INTO v_pilot_count FROM Pilot WHERE commanding_flight = ip_flightID;

    IF (v_plane_type = 'Boeing' AND v_pilot_count < 2) OR 
       (v_plane_type IS NOT NULL AND v_pilot_count < 1) THEN
        UPDATE Flight
        SET next_time = ADDTIME(next_time, '0:30:00')
        WHERE flightID = ip_flightID;
        LEAVE sp_main;
    END IF;
    select legID INTO v_next_leg FROM Route_path WHERE routeID = v_routeID AND sequence = v_progress + 1;
select distance, departure, arrival INTO v_leg_distance, v_current_airport, v_next_airport FROM Leg WHERE legID = v_next_leg;
    SET v_flight_time = leg_time(v_leg_distance, v_speed);
    UPDATE Flight
    SET 
        airplane_status = 'in_flight',
        progress = progress + 1,
        next_time = ADDTIME(next_time, v_flight_time) WHERE flightID = ip_flightID;
    UPDATE Airplane
    SET locationID = NULL
    WHERE airlineID = v_airlineID AND tail_num = v_tail_num;
END //
DELIMITER ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS passengers_board;
DELIMITER //

CREATE PROCEDURE passengers_board (IN ip_flightID VARCHAR(50))
sp_main: BEGIN
    DECLARE v_routeID VARCHAR(50);
    DECLARE v_progress INT;
    DECLARE v_airplane_status VARCHAR(20);
    DECLARE v_current_airport CHAR(3);
    DECLARE v_next_airport CHAR(3);
    DECLARE v_airport_loc VARCHAR(50);
    DECLARE v_seat_capacity INT;
	DECLARE v_tail_num VARCHAR(50);
    DECLARE v_cost INT;
    DECLARE v_current_passengers INT;
    DECLARE v_available_seats INT;
    DECLARE v_airlineID VARCHAR(50);
    DECLARE v_eligible_passengers INT;
    DECLARE v_legID VARCHAR(50);
    IF NOT EXISTS (
        select 1 FROM Flight WHERE flightID = ip_flightID) THEN LEAVE sp_main; END IF;

    select routeID, progress, airplane_status, cost, support_airline, support_tail INTO v_routeID, v_progress, v_airplane_status, v_cost, v_airlineID, v_tail_num
    FROM Flight WHERE flightID = ip_flightID;
	IF v_airplane_status != 'on_ground' THEN LEAVE sp_main; END IF;
    select legID INTO v_legID FROM Route_path WHERE routeID = v_routeID AND sequence = v_progress + 1;
    
    IF v_legID IS NULL THEN LEAVE sp_main; END IF;
    select departure, arrival INTO v_current_airport, v_next_airport FROM Leg WHERE legID = v_legID;
    select locationID INTO v_airport_loc FROM Airport WHERE airportID = v_current_airport;
    select seat_capacity INTO v_seat_capacity FROM Airplane WHERE airlineID = v_airlineID AND tail_num = v_tail_num;
    select COUNT(*) INTO v_current_passengers FROM Person p JOIN Airplane a ON p.locationID = a.locationID WHERE a.airlineID = v_airlineID AND a.tail_num = v_tail_num
    AND p.personID IN (select personID FROM Passenger);

    SET v_available_seats = v_seat_capacity - v_current_passengers;
    select COUNT(*) INTO v_eligible_passengers FROM Person p JOIN Passenger pa ON p.personID = pa.personID JOIN Passenger_vacations pv ON p.personID = pv.personID
    WHERE p.locationID = v_airport_loc
    AND pa.funds >= v_cost AND pv.airportID = v_next_airport AND pv.sequence = 1;
    IF v_eligible_passengers = 0 OR v_available_seats < v_eligible_passengers THEN
        LEAVE sp_main;
    END IF;
    UPDATE Person p JOIN Passenger pa ON p.personID = pa.personID JOIN Passenger_vacations pv ON p.personID = pv.personID JOIN Airplane a ON a.airlineID = v_airlineID AND a.tail_num = v_tail_num
    SET p.locationID = a.locationID,
        pa.funds = pa.funds - v_cost,
        pv.sequence = pv.sequence + 1 WHERE p.locationID = v_airport_loc
    AND pa.funds >= v_cost AND pv.airportID = v_next_airport AND pv.sequence = 1;
END //
DELIMITER ;


-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport. The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin
    DECLARE currentLocation varchar(50);
    DECLARE flightRoute varchar(50);
	DECLARE sp_tail varchar(50);
    DECLARE sp_airline varchar(50);
    DECLARE destAirport char(3);
    DECLARE arrivalLocID varchar(50);
    DECLARE flightStatus varchar(100);
    DECLARE flightProgress int;
    select routeID, progress, airplane_status, support_airline, support_tail into flightRoute, flightProgress, flightStatus, sp_airline, sp_tail
      from flight where flightID = ip_flightID;
    if flightRoute is null then
        leave sp_main;
    end if;
    if flightStatus <> 'on_ground' then
        leave sp_main;
    end if;
    select locationID into currentLocation from airplane where airlineID = sp_airline
       and tail_num  = sp_tail;
    select l.arrival into destAirport from route_path rp join leg l on rp.legID = l.legID where rp.routeID = flightRoute
       and rp.sequence = flightProgress;
    select locationID into arrivalLocID from airport where airportID = destAirport;
    update person
      join passenger_vacations on person.personID = passenger_vacations.personID
       set person.locationID = arrivalLocID
     where person.locationID = currentLocation
       and passenger_vacations.airportID = destAirport;
    delete
      from passenger_vacations
     where personID in (
         select t.personID from (select person.personID from person join passenger_vacations on person.personID = passenger_vacations.personID where person.locationID = arrivalLocID
                  and passenger_vacations.airportID = destAirport
           ) t
     )
       and airportID = destAirport;
end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight. The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight. Also, a pilot can only support
one flight (i.e. one airplane) at a time. The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin
	DECLARE v_routeID VARCHAR(50);
	DECLARE v_max_sequence INT;
    DECLARE v_current_sequence INT;
    DECLARE v_required_license VARCHAR(50);
    DECLARE v_airplane_loc VARCHAR(50);
	DECLARE v_pilot_license VARCHAR(50);
    DECLARE v_flight_airport VARCHAR(50);
	DECLARE v_progress INT;
	DECLARE v_pilot_airport VARCHAR(50);
    IF NOT EXISTS (SELECT 1 FROM flight WHERE flightID = ip_flightID) THEN
		select 'Flight Does Not Exist' AS ErrorMessage;
        LEAVE sp_main;
	END IF;
    IF 'on_ground' != (SELECT airplane_status FROM flight WHERE flightID = ip_flightID) THEN
		select 'Flight Is Not Grounded' AS ErrorMessage;
        LEAVE sp_main;
	END IF;
	select routeID, progress INTO v_routeID, v_progress FROM flight WHERE flightID = ip_flightID;
	select sequence INTO v_current_sequence FROM route_path WHERE routeID = v_routeID AND sequence = v_progress;
	select MAX(sequence) INTO v_max_sequence FROM route_path WHERE routeID = v_routeID;
    
    IF v_current_sequence >= v_max_sequence THEN
		select 'No More Legs to Be Flown on this Route.' AS ErrorMessage;
		LEAVE sp_main;
	END IF;
    IF NOT EXISTS (SELECT 1 FROM Pilot WHERE personID = ip_personID) THEN
		select 'Pilot Does Not Exist' AS ErrorMessage;
        LEAVE sp_main;
    END IF;
    IF (select commanding_flight FROM pilot WHERE personID = ip_personID) IS NOT NULL THEN
		select 'Pilot Already Assigned' AS ErrorMessage;
        LEAVE sp_main;
	END IF;
	select plane_type INTO v_required_license FROM airplane
	WHERE tail_num = (select support_tail FROM flight WHERE flightID = ip_flightID);
	select license INTO v_pilot_license FROM pilot_licenses
	WHERE personID = ip_personID AND license = v_required_license;
	IF v_pilot_license IS NULL THEN
		select 'Pilot Does Not Hold The Correct License For This Flight.' AS ErrorMessage;
		LEAVE sp_main;
	END IF;

	select airportID INTO v_flight_airport FROM airport WHERE country =
    (select arrival FROM leg WHERE legID = (select legID FROM route_path WHERE routeID = v_routeID and sequence = v_progress));
	select locationID INTO v_pilot_airport FROM person WHERE personID = ip_personID;
	IF v_flight_airport != v_pilot_airport THEN
		select 'Pilot Not Located At Correct Airport.' AS ErrorMessage;
		LEAVE sp_main;
	END IF;
	SELECT locationID INTO v_airplane_loc FROM airplane WHERE tail_num = (SELECT support_tail FROM flight WHERE flightID = ip_flightID);
    UPDATE pilot SET commanding_flight = ip_flightID WHERE personID = ip_personID;
    UPDATE person SET locationID = v_airplane_loc WHERE personID = ip_personID;
END //
DELIMITER ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin
    DECLARE flightStatus varchar(100);
    DECLARE flightProgress int;
    DECLARE destAirport char(3);
    DECLARE sp_airline varchar(50);
    DECLARE sp_tail varchar(50);
    DECLARE totalLegs int default 0;
    DECLARE airplaneLocation varchar(50);
    DECLARE arrivalLocID varchar(50);
    DECLARE flightRoute varchar(50);
    DECLARE passengerCount int default 0;
    
    select airplane_status, progress, routeID, support_airline, support_tail into flightStatus, flightProgress, flightRoute, sp_airline, sp_tail
      from flight where flightID = ip_flightID;
    if flightStatus <> 'on_ground' then
        leave sp_main;
    end if;
    select count(*) into totalLegs from route_path where routeID = flightRoute;
    if flightProgress < totalLegs then
        leave sp_main;
    end if;
    select locationID into airplaneLocation from airplane where airlineID = sp_airline and tail_num  = sp_tail;
    select count(*) into passengerCount from person p join passenger pas on p.personID = pas.personID where p.locationID = airplaneLocation;
    if passengerCount > 0 then
        leave sp_main;
    end if;
    update pilot
       set commanding_flight = null
     where commanding_flight = ip_flightID;
    select l.arrival into destAirport from route_path rp join leg l on rp.legID = l.legID where rp.routeID = flightRoute
       and rp.sequence = flightProgress;
select locationID into arrivalLocID from airport where airportID = destAirport;
    update person
      join pilot on person.personID = pilot.personID
       set person.locationID = arrivalLocID
     where pilot.commanding_flight is null
       and person.locationID = airplaneLocation;
end //
delimiter ;


-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin
    if not exists (select 1 from flight where flightID = ip_flightID) then
        select 'Flight Does Not Exist' as ErrorMessage;
        leave sp_main;
    end if;
    if not exists (select 1 from flight where flightID = ip_flightID and airplane_status = 'on_ground') then
        select 'Flight Is Not On The Ground' as ErrorMessage;
        leave sp_main;
    end if;
    if not exists (
        select 1 from flight f join route r on f.routeID = r.routeID join route_path rp on r.routeID = rp.routeID join leg l on rp.legID = l.legID
        where f.flightID = ip_flightID and (l.departure = (select airportID from airport where airportID = l.departure) or l.arrival = (select airportID from airport where airportID = l.arrival))
    ) then
        select 'Flight Is Not At The Beginning Or End Of Its Route' as ErrorMessage;
        leave sp_main;
    end if;
    delete from flight where flightID = ip_flightID;
end //
delimiter ;

-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin
    DECLARE nextFlightID varchar(50);
    DECLARE flightRoute varchar(50);
	DECLARE flightStatus varchar(100);
    DECLARE flightProgress int;
    DECLARE totalLegs int default 0;
    select flightID, airplane_status into nextFlightID, flightStatus from flight
     order by next_time asc,(case when airplane_status = 'in_flight' then 0 else 1 end) asc,flightID asc
     limit 1;

    if nextFlightID is null then
        leave sp_main;
    end if;
    select progress, routeID into flightProgress, flightRoute from flight where flightID = nextFlightID;
    select count(*) into totalLegs from route_path where routeID = flightRoute;
   if flightStatus = 'in_flight' then
        call flight_landing(nextFlightID);
        call passengers_disembark(nextFlightID);
        select progress into flightProgress from flight where flightID = nextFlightID;
if flightProgress >= totalLegs then
            call recycle_crew(nextFlightID);
            call retire_flight(nextFlightID);
        end if;
    elseif flightStatus = 'on_ground' then
        select progress into flightProgress from flight where flightID = nextFlightID;
if flightProgress >= totalLegs then
            call recycle_crew(nextFlightID);
            call retire_flight(nextFlightID);
        else
            call passengers_board(nextFlightID);
            call flight_takeoff(nextFlightID);
        end if;
    end if;
end //
delimiter ;

-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located.
We need to display what airports these flights are departing from, what airports
they are arriving at, the number of flights that are flying between the
departure and arrival airport, the list of those flights (ordered by their
flight IDs), the earliest and latest arrival times for the destinations and the
list of planes (by their respective flight IDs) flying these flights. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air (
departing_from, 
arriving_at,
num_flights, 
flight_list, 
earliest_arrival, 
latest_arrival, 
airplane_list) as
select

-- This view describes where flights that are currently airborne are located.
		specificLeg.departure as departing_from, specificLeg.arrival as arriving_at, COUNT(DISTINCT specificFlight.flightID) as num_flights, GROUP_CONCAT(DISTINCT specificFlight.flightID ORDER BY specificFlight.flightID SEPARATOR ', ') AS flight_list, min(specificFlight.next_time) as earliest_arrival, max(specificFlight.next_time) as latest_arrival, GROUP_CONCAT(DISTINCT specificAirplane.locationID ORDER BY specificFlight.flightID SEPARATOR ', ') AS airplane_list
        
FROM flight specificFlight 

-- We need to display what airports these flights are departing from

JOIN route_path specificRoutePath ON specificFlight.routeID = specificRoutePath.routeID and specificFlight.progress = specificRoutePath.sequence

-- what airports they are arriving at

JOIN leg specificLeg ON specificRoutePath.legID = specificLeg.legID

-- number of flights that are flying between the departure and arrival airport,

JOIN airplane specificAirplane ON specificAirplane.tail_num = specificFlight.support_tail

-- list of those flights,

WHERE specificFlight.airplane_status = 'in_flight'

-- earliest and latest arrival times for the destinations and the list of planes (by the location id) flying these flights

GROUP BY specificLeg.departure, specificLeg.arrival;


-- [15] flights_on_the_ground()
-- ------------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are
located. We need to display what airports these flights are departing from, how
many flights are departing from each airport, the list of flights departing from
each airport (ordered by their flight IDs), the earliest and latest arrival time
amongst all of these flights at each airport, and the list of planes (by their
respective flight IDs) that are departing from each airport.*/
-- ------------------------------------------------------------------------------
create or replace view flights_on_the_ground (
departing_from, 
num_flights,
flight_list, 
earliest_arrival, 
latest_arrival, 
airplane_list) as

-- This view describes where flights that are currently on the ground are located

select
		specificLeg.arrival as departing_from, COUNT(DISTINCT specificFlight.flightID) as num_flights, GROUP_CONCAT(DISTINCT specificFlight.flightID ORDER BY specificFlight.flightID SEPARATOR ', ') AS flight_list, min(specificFlight.next_time) as earliest_arrival, max(specificFlight.next_time) as latest_arrival, GROUP_CONCAT(DISTINCT specificAirplane.locationID ORDER BY specificFlight.flightID SEPARATOR ', ') AS airplane_list
        
FROM flight specificFlight 

-- We need to display what airports these flights are departing from

JOIN route_path specificRoutePath ON specificFlight.routeID = specificRoutePath.routeID and specificFlight.progress = specificRoutePath.sequence

-- how many flights are departing from each airport,

JOIN leg specificLeg ON specificRoutePath.legID = specificLeg.legID

-- the list of flights departing from each airport

JOIN airplane specificAirplane ON specificAirplane.tail_num = specificFlight.support_tail

-- the earliest and latest arrival time amongst all of these flights at each airport,

WHERE specificFlight.airplane_status = 'on_ground'

GROUP BY specificLeg.arrival

UNION

-- list of planes (by their location id) that are departing from each airport
select
		specificLeg.departure as departing_from, COUNT(DISTINCT specificFlight.flightID) as num_flights, GROUP_CONCAT(DISTINCT specificFlight.flightID ORDER BY specificFlight.flightID SEPARATOR ', ') AS flight_list, min(specificFlight.next_time) as earliest_arrival, max(specificFlight.next_time) as latest_arrival, GROUP_CONCAT(DISTINCT specificAirplane.locationID ORDER BY specificFlight.flightID SEPARATOR ', ') AS airplane_list
        
        
FROM flight specificFlight 


JOIN route_path specificRoutePath ON specificFlight.routeID = specificRoutePath.routeID and (specificFlight.progress + 1) = specificRoutePath.sequence


JOIN leg specificLeg ON specificRoutePath.legID = specificLeg.legID


JOIN airplane specificAirplane ON specificAirplane.tail_num = specificFlight.support_tail


WHERE specificFlight.airplane_status = 'on_ground'


GROUP BY specificLeg.departure;
    

-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. We 
need to display what airports these people are departing from, what airports 
they are arriving at, the list of planes (by the location id) flying these 
people, the list of flights these people are on (by flight ID), the earliest 
and latest arrival times of these people, the number of these people that are 
pilots, the number of these people that are passengers, the total number of 
people on the airplane, and the list of these people by their person id. */
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW people_in_the_air (
    departing_from, arriving_at, num_airplanes, airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots, num_passengers, joint_pilots_passengers, person_list
) AS
SELECT 
    specificLeg.departure AS departing_from, specificLeg.arrival AS arriving_at, COUNT(DISTINCT CONCAT(specificFlight.support_airline, '-', specificFlight.support_tail)) AS num_airplanes, GROUP_CONCAT(DISTINCT specificAirplane.locationID ORDER BY specificAirplane.locationID SEPARATOR ',') AS airplane_list, GROUP_CONCAT(DISTINCT specificFlight.flightID ORDER BY specificFlight.flightID SEPARATOR ',') AS flight_list, MIN(specificFlight.next_time) AS earliest_arrival, MAX(specificFlight.next_time) AS latest_arrival,
    
    SUM(CASE WHEN specificPilot.personID IS NOT NULL THEN 1 ELSE 0 END) AS num_pilots, SUM(CASE WHEN specificPassenger.personID IS NOT NULL THEN 1 ELSE 0 END) AS num_passengers, COUNT(DISTINCT specificPerson.personID) AS joint_pilots_passengers, GROUP_CONCAT(DISTINCT specificPerson.personID ORDER BY specificPerson.personID SEPARATOR ',') AS person_list
    
FROM Person specificPerson


JOIN Airplane specificAirplane ON specificPerson.locationID = specificAirplane.locationID


JOIN Flight specificFlight ON specificAirplane.airlineID = specificFlight.support_airline AND specificAirplane.tail_num = specificFlight.support_tail


JOIN Route_path specificRoute ON specificFlight.routeID = specificRoute.routeID AND specificFlight.progress = specificRoute.sequence


JOIN Leg specificLeg ON specificRoute.legID = specificLeg.legID


LEFT JOIN Pilot specificPilot ON specificPerson.personID = specificPilot.personID AND specificPilot.commanding_flight = specificFlight.flightID


LEFT JOIN Passenger specificPassenger ON specificPerson.personID = specificPassenger.personID


WHERE specificFlight.airplane_status = 'in_flight'


GROUP BY specificLeg.departure, specificLeg.arrival;


-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground and in an
airport are located. We need to display what airports these people are departing
from by airport id, location id, and airport name, the city and state of these
airports, the number of these people that are pilots, the number of these people
that are passengers, the total number people at the airport, and the list of
these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground (
departing_from, 
airport, 
airport_name,
city, 
state, 
country, 
num_pilots, 
num_passengers, 
joint_pilots_passengers,
person_list) as
SELECT 
    specificAirport.airportID AS airport_id, specificAirport.locationID AS location_id, specificAirport.airport_name, specificAirport.city, specificAirport.state, specificAirport.country,
    
    COUNT(DISTINCT CASE WHEN specificPilot.personID IS NOT NULL THEN specificPerson.personID END) AS num_pilots, COUNT(DISTINCT CASE WHEN specificPassenger.personID IS NOT NULL THEN specificPerson.personID END) AS num_passengers, COUNT(DISTINCT specificPerson.personID) AS joint_pilots_passengers, GROUP_CONCAT(DISTINCT specificPerson.personID ORDER BY specificPerson.personID SEPARATOR ',') AS person_list
    
FROM Person specificPerson

JOIN Airport specificAirport ON specificPerson.locationID = specificAirport.locationID

LEFT JOIN Pilot specificPilot ON specificPerson.personID = specificPilot.personID

LEFT JOIN Passenger specificPassenger ON specificPerson.personID = specificPassenger.personID

WHERE specificPerson.locationID IN (SELECT locationID FROM Airport)



GROUP BY 

    specificAirport.airportID, specificAirport.locationID, specificAirport.airport_name, specificAirport.city, specificAirport.state, specificAirport.country;

-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view will give a summary of every route. This will include the routeID,
the number of legs per route, the legs of the route in sequence, the total
distance of the route, the number of flights on this route, the flightIDs of
those flights by flight ID, and the sequence of airports visited by the route. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
num_flights, flight_list, airport_sequence) as
SELECT

	-- This view will give a summary of every route.
    specificAirportRoute.routeID AS route, COUNT(DISTINCT specificRP.sequence) AS num_legs, GROUP_CONCAT(DISTINCT specificRP.legID ORDER BY specificRP.sequence SEPARATOR ',') AS leg_sequence,
    
    
    -- This will include the routeID
    (SELECT SUM(specificLeg2.distance) 
    
    -- number of legs per route
     FROM route_path specificRP2 
     
     -- legs of the route in sequence
     JOIN leg specificLeg2 ON specificRP2.legID = specificLeg2.legID 
     
     -- total distance of the route
     
     WHERE specificRP2.routeID = specificAirportRoute.routeID) AS route_length, COUNT(DISTINCT specificFlight.flightID) AS num_flights, GROUP_CONCAT(DISTINCT specificFlight.flightID ORDER BY specificFlight.flightID SEPARATOR ',') AS flight_list, GROUP_CONCAT(DISTINCT CONCAT(specificLeg.departure, '->', specificLeg.arrival) ORDER BY specificRP.sequence SEPARATOR ',') AS airport_sequence

     -- number of flights on this route
FROM route specificAirportRoute
-- flightIDs of those flights
LEFT JOIN route_path specificRP ON specificAirportRoute.routeID = specificRP.routeID
LEFT JOIN leg specificLeg ON specificRP.legID = specificLeg.legID
LEFT JOIN flight specificFlight ON specificAirportRoute.routeID = specificFlight.routeID
 -- sequence of airports visited by the route
GROUP BY specificAirportRoute.routeID;

-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. It should
specify the city, state, the number of airports shared, and the lists of the
airport codes and airport names that are shared both by airport ID. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, country, num_airports,
airport_code_list, airport_name_list) as

-- This view displays airports that share the same city and state
SELECT
    specificAirport.city, specificAirport.state, specificAirport.country,
    
-- lists of the airport codes and airport names that are shared

    COUNT(*) AS num_airports,
    
    GROUP_CONCAT(specificAirport.airportID ORDER BY specificAirport.airportID SEPARATOR ', ') AS airport_code_list,
    
    GROUP_CONCAT(specificAirport.airport_name SEPARATOR ', ') AS airport_name_list
    
--  It should specify the city, state, the number of airports shared

FROM airport specificAirport

GROUP BY specificAirport.city, 

specificAirport.state, 

specificAirport.country

HAVING COUNT(*) > 1;