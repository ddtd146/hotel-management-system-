/* Author: Dang Tien Dung
StudentId: 20215011
About: SQL query file for hotel-management-database */



---------------------------------------------------------
-- Query ------------------------------------------------

---- number of customer check_in group by month in this year
SELECT EXTRACT (MONTH FROM check_in_time) AS month, COUNT(*) num_check_in FROM check_in_out
WHERE check_in_time <= '2023-12-31' AND check_in_time >= '2023-01-01' 
GROUP BY (EXTRACT (MONTH FROM check_in_time))
ORDER BY COUNT(*) DESC

---- list of empty double rooms in floor 7, 8, 9
SELECT * FROM room
JOIN tag USING (room_id)
JOIN category USING (cat_id) 
WHERE status = 'E' AND number SIMILAR TO '[7-9]%' AND tagname = 'DOUBLE';

---- List of groups which have more than 4 people in this month
SELECT booking_id, leader_id, count(*) as num_member FROM check_in_out 
WHERE check_in_time >= '2023-07-01' AND check_in_time <= '2023-07-31'
GROUP BY (booking_id, leader_id)
HAVING (count(*) >= 5);

--- List of vouchers which owned by customer (can apply)

SELECT * FROM voucher v
JOIN apply a USING (voucher_id)
JOIN customer c USING (cus_id)
WHERE c.cus_id = '00000001' AND status = 'X' 
AND ((v.starting_date <= NOW()::date AND (v.expiry_date >= NOW()::date OR v.expiry_date IS NULL)) OR v.num = -1) ;

--- Filter by tagname of room

SELECT r.* FROM room AS r
JOIN tag t USING(room_id)
JOIN category c USING (cat_id) 
WHERE c.tagname IN ('Double', 'Sea View')
GROUP BY (r.*) 
HAVING count(*) = 2;

---------------------------------------------------------
-- Function ---------------------------------------------

---- to apply voucher to a booking
CREATE OR REPLACE FUNCTION fnc_apply_voucher(in voucherid char(8), in bookingid integer) RETURNS void AS
$$
DECLARE 
	leaderid char(8);
BEGIN
  SELECT cus_id INTO leaderid FROM booking 
  WHERE booking_id = bookingid;
  if voucherid NOT IN (SELECT voucher_id FROM voucher v
    JOIN apply a USING (voucher_id)
    JOIN  customer c USING (cus_id)
    WHERE c.cus_id = leaderid AND status = 'X' 
    AND (v.starting_date <= NOW()::date AND v.expiry_date >= NOW()::date OR v.num = -1) ) then
    RAISE NOTICE 'Voucher % not found', voucherid;
	return;
  end if;
  if NOT EXISTS (SELECT booking_id FROM booking WHERE booking_id = bookingid) then 
    RAISE NOTICE 'Booking % not found', bookingid;
    return;
  end if; 
  INSERT INTO include(voucher_id, booking_id) VALUES (voucherid, bookingid);
  UPDATE apply 
  SET status = 'U'
  WHERE cus_id = leaderid AND voucher_id = voucherid; 
END;
$$
LANGUAGE plpgsql;


---- to check-in customer
CREATE OR REPLACE FUNCTION fnc_check_in(in cusid char(8), in bookingid integer) RETURNS void AS 
$$
DECLARE
		checkindate DATE;
		los INTEGER;
		leaderid char(8);
BEGIN
  if NOT EXISTS (SELECT 1 FROM customer WHERE cus_id = cusid) then
    RAISE NOTICE 'Customer % not found', cusid;
	return;
  end if;
  SELECT b.check_in_date INTO checkindate FROM booking b
  WHERE booking_id = bookingid;
  if checkindate IS NULL then 
    RAISE NOTICE 'Booking % not found', bookingid;
    return;
  end if;
  if checkindate > NOW()::date then 
    RAISE NOTICE 'Too soon. Coming later';
    return;
  end if;
  SELECT max(length_of_stay) INTO los FROM booking 
   JOIN booking_line USING (booking_id)
   WHERE booking_id = bookingid;
  if checkindate + los <= NOW()::date then 
    RAISE NOTICE 'Too late. Cant checkin';
    return;
  end if;
  SELECT cus_id INTO leaderid FROM customer
  JOIN booking USING (cus_id) 
  WHERE booking_id = bookingid;
  INSERT INTO check_in_out(booking_id, cus_id, leader_id, check_in_status) VALUES (bookingid, cusid, leaderid, 'I');
  return;
END;
$$
LANGUAGE plpgsql;

---- to check-out customer 

CREATE OR REPLACE FUNCTION fnc_check_out(in cusid char(8), in bookingid integer) RETURNS void AS 
$$
DECLARE 
  checkinstatus char(1);
BEGIN 
  if NOT EXISTS (SELECT 1 FROM customer WHERE cus_id = cusid) then
    RAISE NOTICE 'Customer % not found', cusid;
    return;
  end if;
  SELECT check_in_status INTO checkinstatus FROM check_in_out
  WHERE booking_id = bookingid AND cus_id = cusid;
  if NOT EXISTS (SELECT 1 FROM booking WHERE booking_id = bookingid) then 
    RAISE NOTICE 'Booking % not found', bookingid;
    return;
  end if;
  if checkinstatus = 'X' OR checkinstatus IS NULL then 
    RAISE NOTICE 'You have not checked in before';
    return;
  end if;
  UPDATE check_in_out 
  SET check_out_status = 'O'
  WHERE booking_id = bookingid AND cus_id = cusid;
END;

$$
LANGUAGE plpgsql;


---- create booking and book rooms
------ create booking
CREATE OR REPLACE FUNCTION fnc_cre_booking(in cusid char(8)) RETURNS void AS 
$$
DECLARE type char(8);
BEGIN 
  SELECT type_id INTO type FROM customer
  WHERE cus_id = cusid;
  if type IS NULL then 
	RAISE NOTICE 'Customer % not found', cusid;
	return;
  end if;
  if type = '00001111' then 
  	RAISE NOTICE 'Provide CCCD pls';
	return;
  end if;
  INSERT INTO booking(cus_id) VALUES (cusid);
  return;
END;
$$
LANGUAGE plpgsql;

------ book room
CREATE OR REPLACE FUNCTION fnc_book_room(in bookingid INTEGER, in roomid char(8), in los INTEGER) RETURNS void AS
$$
DECLARE 
  roomstatus char(1);
BEGIN 
  if (los <= 0) then 
    RAISE NOTICE 'length of stay cant be <= 0';
    return;
  end if;
  if NOT EXISTS (SELECT booking_id FROM booking WHERE booking_id = bookingid) then 
    RAISE NOTICE 'Booking % not found', bookingid;
    return;
  end if; 
  SELECT status INTO roomstatus FROM room WHERE room_id = roomid;
  if (roomstatus IS NULL) then
    RAISE NOTICE 'Room % not found', roomid;
    return;
  end if;
  if (roomstatus = 'U') then 
    RAISE NOTICE 'Room % is using by someone else', roomid;
    return;
  end if;
  if (roomstatus = 'X') then
    RAISE NOTICE 'Room % is not available', roomid;
    return;
  end if; 
  INSERT INTO booking_line(booking_id, room_id, length_of_stay) VALUES (bookingid, roomid, los);
  return;
END;
$$ 
LANGUAGE plpgsql;

---- to give voucher 
CREATE OR REPLACE FUNCTION fnc_give_voucher(in voucherid char(8), in cusid char(8)) returns void AS
$$
DECLARE 
  num_vch INTEGER;
BEGIN
  if NOT EXISTS (SELECT 1 FROM voucher WHERE voucher_id = voucherid ) then
    RAISE NOTICE 'Voucher % not found', voucherid;
	return;
  end if;
  if NOT EXISTS (SELECT 1 FROM customer WHERE cus_id = cusid ) then
    RAISE NOTICE 'Customer % not found', cusid;
	return;
  end if;
  SELECT num into num_vch FROM voucher 
  WHERE voucher_id = voucherid;
  if (num_vch >= 0) then
    if num_vch = 0 then 
      RAISE NOTICE 'The number of voucher % is zero', voucherid;
      return;
    end if;
  	UPDATE voucher  
  	SET num = num - 1
  	WHERE voucher_id = voucherid;
  end if;
  INSERT INTO apply(voucher_id, cus_id) VALUES(voucherid, cusid);
END;
$$
LANGUAGE plpgsql;

---------------------------------------------------------
-- Trigger-----------------------------------------------

---- give default voucher for new customer
CREATE FUNCTION trgfnc_defaut_give_voucher() RETURNS TRIGGER AS 
$$
BEGIN
  INSERT INTO apply(voucher_id, cus_id) VALUES ('00000000', NEW.cus_id);
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_default_give_voucher 
AFTER INSERT ON customer 
FOR EACH ROW 
EXECUTE PROCEDURE trgfnc_defaut_give_voucher();


---- defaut customer type 
CREATE FUNCTION trgfnc_default_customer_type() RETURNS trigger AS
$$
BEGIN 
  if NEW.cccd IS NOT NULL then 
    UPDATE customer
    SET type_id = '00000000' 
    WHERE cus_id = NEW.cus_id;
  end if;
  return NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_default_customer_type 
AFTER INSERT ON customer 
FOR EACH ROW 
EXECUTE PROCEDURE trgfnc_default_customer_type();


---- to calculate price of each line in a booking
CREATE OR REPLACE FUNCTION trgfnc_cal_booking_line() RETURNS trigger AS
$$
DECLARE 
  price_per_night MONEY;
BEGIN
  if (TG_OP = 'UPDATE') then
  	if OLD.booking_id IS DISTINCT FROM NEW.booking_id then 
      RAISE NOTICE 'cant change booking_id';
      RETURN NULL;
	end if;
    if OLD.price IS DISTINCT FROM NEW.price then  
      return new;
    end if;
  end if;
  SELECT price INTO price_per_night FROM room
  WHERE room_id = NEW.room_id;
  UPDATE booking_line 
  SET price = length_of_stay * price_per_night
  WHERE room_id = NEW.room_id AND booking_id = NEW.booking_id;
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_cal_booking_line 
AFTER INSERT OR UPDATE ON booking_line
FOR EACH ROW 
EXECUTE FUNCTION trgfnc_cal_booking_line();


---- to calculate total price (before apply voucher) of a booking
CREATE OR REPLACE FUNCTION trgfnc_cal_total() RETURNS trigger AS
$$
BEGIN
  if (TG_OP = 'INSERT') then
    UPDATE booking
    SET total_price = total_price + NEW.price
    WHERE booking_id = NEW.booking_id;
    RETURN NEW;
  end if;
  if (TG_OP = 'UPDATE') then 
    if NEW.booking_id IS DISTINCT FROM OLD.booking_id then 
      RAISE NOTICE 'U cant change booking_id';
      RETURN NULL;
    end if;
    if NEW.length_of_stay <= 0 then 
      RAISE NOTICE 'los cant <= 0';
      RETURN NULL;
    end if;
    UPDATE booking
    SET total_price = total_price + NEW.price - OLD.price
    WHERE booking_id = NEW.booking_id;
    RETURN NEW;
  end if;
  UPDATE booking
  SET total_price = total_price - OLD.price
  WHERE booking_id = OLD.booking_id;
  RETURN NULL; 
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_cal_total_bkline_aftinsdel
AFTER INSERT OR DELETE ON booking_line 
FOR EACH ROW
EXECUTE FUNCTION trgfnc_cal_total();

CREATE OR REPLACE TRIGGER trg_cal_total_bkline_befupd
BEFORE UPDATE ON booking_line 
FOR EACH ROW
EXECUTE FUNCTION trgfnc_cal_total();


---- to calculate final price of a booking
CREATE OR REPLACE FUNCTION trgfnc_cal_final() RETURNS trigger AS 
$$
DECLARE 
  percent float;
  final money;
  total money;
  bookingid int;
BEGIN  
  if (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') then 
    SELECT total_price, booking_id INTO total, bookingid FROM booking
    WHERE booking_id = NEW.booking_id;
  else 
    SELECT total_price, booking_id INTO total, bookingid FROM booking
    WHERE booking_id = OLD.booking_id;
  end if;
  final = total;
  for percent in (SELECT percentage FROM voucher 
    JOIN include USING (voucher_id)
    WHERE booking_id = bookingid) loop
    final = final - total * percent / 100;
  end loop;
  UPDATE booking 
  SET final_price = final
  WHERE booking_id = bookingid;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_cal_final_include
AFTER INSERT OR DELETE ON include
FOR EACH ROW 
EXECUTE FUNCTION trgfnc_cal_final();

CREATE TRIGGER trg_cal_final_booking
AFTER UPDATE ON booking
FOR EACH ROW  
WHEN (NEW.total_price IS DISTINCT FROM OLD.total_price)
EXECUTE FUNCTION trgfnc_cal_final();


