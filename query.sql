--1. Danh sach cac phong doi con trong va o 3 tang cao nhat
SELECT * FROM room
JOIN tag USING (room_id)
JOIN category USING (cat_id) 
WHERE status = 'E' AND number SIMILAR TO '[7-9]%' AND tagname = 'DOUBLE'

--2. Danh sach cac doan tren 5 nguoi trong thang nay 
SELECT booking_id, leader_id, count(*) as num_member FROM check_in_out 
WHERE check_in_time >= '2023-07-01' AND check_in_time <= '2023-07-31'
GROUP BY (booking_id, leader_id)
HAVING (count(*) >= 5)

--3. Danh sach voucher co the ap dung cua khach hang

SELECT * FROM voucher v
JOIN apply a USING (voucher_id)
JOIN customer c USING (cus_id)
WHERE c.cus_id = '00000001' AND status = 'X' 
AND (v.starting_date <= NOW()::date AND v.expiry_date >= NOW()::date OR v.num = -1) 

--4. Filter theo tagname

SELECT r.* FROM room AS r
JOIN tag t USING(room_id)
JOIN category c USING (cat_id) 
WHERE c.tagname IN ('Double', 'Sea View')
GROUP BY (r.*) 
HAVING count(*) = 2

--5. function apply voucher
CREATE OR REPLACE FUNCTION fnc_apply_voucher(in voucherid char(8), in cusid char(8)) returns void AS
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

--6 trigger default apply voucher
CREATE FUNCTION trgfnc_defaut_apply_voucher() RETURNS TRIGGER AS 
$$
BEGIN
  INSERT INTO apply(voucher_id, cus_id) VALUES ('00000000', NEW.cus_id);
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_default_apply_voucher 
AFTER INSERT ON customer 
FOR EACH ROW 
EXECUTE PROCEDURE trgfnc_defaut_apply_voucher()

--7 tao don va dat phong 
--create booking
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

--book room
CREATE OR REPLACE FUNCTION fnc_book_room(in bookingid INTEGER, in roomid char(8), in los INTEGER) RETURNS void AS
$$
BEGIN 
  if (los <= 0) then 
    RAISE NOTICE 'length of stay cant be <= 0';
    return;
  end if;
  if NOT EXISTS (SELECT booking_id FROM booking WHERE booking_id = bookingid) then 
    RAISE NOTICE 'Booking % not found', bookingid;
    return;
  end if; 
  if NOT EXISTS (SELECT room_id FROM room WHERE room_id = roomid) then 
    RAISE NOTICE 'Room % not found', roomid;
    return;
  end if;
  INSERT INTO booking_line(booking_id, room_id, length_of_stay) VALUES (bookingid, roomid, los);
  return;
END;
$$ 
LANGUAGE plpgsql;


--8 Luong khach check-in theo thang 
SELECT EXTRACT (MONTH FROM check_in_time) AS month, COUNT(*) num_check_in FROM check_in_out 
GROUP BY (EXTRACT (MONTH FROM check_in_time))

--9 fnc check-in 
CREATE OR REPLACE FUNCTION fnc_check_in(in cusid char(8), in bookingid INTEGER) RETURNS DATE AS 
$$
DECLARE
		checkindate DATE;
		los INTEGER;
		leaderid char(8);
BEGIN
  if NOT EXISTS (SELECT 1 FROM customer WHERE cus_id = cusid) then
    RAISE NOTICE 'Customer % not found', cusid;
	return null;
  end if;
  SELECT b.check_in_date INTO checkindate FROM booking b
  WHERE booking_id = bookingid;
  if checkindate IS NULL then 
    RAISE NOTICE 'Booking % not found', bookingid;
    return null;
  end if;
  if checkindate > NOW()::date then 
    RAISE NOTICE 'Too soon. Coming later';
    return checkindate;
  end if;
  SELECT max(length_of_stay) INTO los FROM booking 
   JOIN booking_line USING (booking_id)
   WHERE booking_id = bookingid;
  if checkindate + los <= NOW()::date then 
    RAISE NOTICE 'Too late. Cant checkin';
    return checkindate + los;
  end if;
  SELECT cus_id INTO leaderid FROM customer
  JOIN booking USING (cus_id) 
  WHERE booking_id = bookingid;
  INSERT INTO check_in_out(booking_id, cus_id, leader_id, check_in_status) VALUES (bookingid, cusid, leaderid, 'I');
  return checkindate;
END;
$$
LANGUAGE plpgsql;

--10 trigger defaut customer type
CREATE FUNCTION trgfnc_defaulttomer_type() RETURNS trigger AS
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

CREATE TRIGGER trg_defaulttomer_type 
AFTER INSERT ON customer 
FOR EACH ROW 
EXECUTE PROCEDURE trgfnc_defaulttomer_type();

--11 thanh toan 
CREATE FUNCTION fnc_pay() RETURNS money AS 
$$
BEGIN
END
$$
LANGUAGE plpgsql;

