--1. View
--+ Hien thi thong tin co ban cua khach hang:
CREATE OR REPLACE VIEW booking_info AS
SELECT b.booking_id, b.cus_id, c.first_name, c.last_name, ct.name AS customer_type,
       (SELECT COUNT(*) FROM booking_line WHERE booking_id = b.booking_id) AS total_rooms
FROM booking b
JOIN customer c ON b.cus_id = c.cus_id
JOIN customer_type ct ON c.type_id = ct.type_id;

--2. Query 
--+ Hien thi thong tin cac phong co the se duoc su dung va dang duoc su dung trong thang 7/2023
SELECT DISTINCT r.room_id, r.number, r.description, r.status, r.price
FROM room r
LEFT JOIN booking_line bl ON r.room_id = bl.room_id
LEFT JOIN check_in_out cio ON r.room_id = cio.room_id
WHERE (bl.time >= '2023-07-01' AND bl.time < '2023-08-01') 
   OR (cio.check_in_time >= '2023-07-01' AND cio.check_in_time < '2023-08-01') 
   OR (cio.check_out_time >= '2023-07-01' AND cio.check_out_time < '2023-08-01')
   OR (cio.check_in_time < '2023-07-01' AND cio.check_out_time >= '2023-08-01') 
   OR (cio.check_in_time < '2023-07-01' AND cio.check_out_time IS NULL); 

--+ Hien thi thong tin ve nhung don hang da thanh toan (status = 'O') va kem theo ten khach hang va tong gia tien thanh toan:
SELECT 
 b.booking_id,
 c.first_name || ' ' || c.last_name AS customer_name,
 b.final_price
FROM booking b
INNER JOIN customer c ON b.cus_id = c.cus_id
WHERE b.status = 'O';

--+ Hien thi thong tin ve cac voucher da het han va so luong voucher da tang duoc cho khach hang truoc khi no het han:
SELECT 
 v.voucher_id,
 v.name,
 v.expiry_date,
 COUNT(a.voucher_id) AS num_uses
FROM voucher v
LEFT JOIN apply a ON v.voucher_id = a.voucher_id
WHERE v.expiry_date < NOW()::date
GROUP BY v.voucher_id, v.name, v.expiry_date;

--+ In ra ti le su dung phong (phong duoc su dung / tong so phong co the su dung):
SELECT 
    COUNT(CASE WHEN status = 'U' THEN 1 END) / (COUNT(*) - COUNT(CASE WHEN status = 'X' THEN 1 END)) AS room_usage_rate
FROM 
    room;

--+ Hien thi thong tin ve cac loai khach hang va so luong khach hang tuong ung:
SELECT 
    ct.type_id,
    ct.name,
    COUNT(c.cus_id) AS num_customers
FROM customer_type ct
LEFT JOIN customer c ON ct.type_id = c.type_id
GROUP BY ct.type_id, ct.name;   

--3. Function
--+ Nhap vao 1 tagname sau do in ra thong tin cua tat ca cac phong trong khach san con trong chua duoc thue co cung tagname duoc nhap vao:
CREATE OR REPLACE FUNCTION find_rooms_by_tag(tagname_input TEXT)
RETURNS TABLE (room_id INT, number INT, description VARCHAR, status CHAR, price NUMERIC)
AS $$
BEGIN
    RETURN QUERY
    SELECT r.room_id, r.number, r.description, r.price
    FROM room r
    INNER JOIN tag t ON r.room_id = t.room_id
    INNER JOIN category c ON t.cat_id = c.cat_id
    WHERE r.status = 'E' AND c.tagname = tagname_input;
END;
$$
LANGUAGE plpgsql;

--+ In ra thong tin cua nhung phong chua duoc thue va co gia tien nho hon gia tien ma ban nhap vao:
CREATE OR REPLACE FUNCTION find_available_rooms_with_price_less_than(price_input NUMERIC)
RETURNS TABLE (
    room_id INT,
    room_number INT,
    description VARCHAR,
    status CHAR,
    price NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        room_id,
        number,
        description,
        status,
        price
    FROM 
        room
    WHERE 
        status = 'E' 
        AND price < price_input 
        AND NOT EXISTS (
            SELECT 1
            FROM booking_line bl
            WHERE bl.room_id = room.room_id
        ); 
END;
$$ LANGUAGE plpgsql;

--4. Trigger 
--+ Tu dong cap nhat trang thai cua phong sau khi 1 don hang duoc tao
CREATE OR REPLACE FUNCTION update_room_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_in_date + NEW.length_of_stay >= NOW() AND NEW.check_in_date <= NOW() THEN
        UPDATE room
        SET status = 'U'
        WHERE room_id = (SELECT room_id FROM booking_line WHERE booking_id = NEW.booking_id);
    ELSE
        UPDATE room
        SET status = 'E'
        WHERE room_id = (SELECT room_id FROM booking_line WHERE booking_id = NEW.booking_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_room_status_trigger
BEFORE UPDATE ON booking
FOR EACH ROW
EXECUTE FUNCTION update_room_status();

CREATE TRIGGER update_room_status_trigger
BEFORE UPDATE ON booking_line
FOR EACH ROW
EXECUTE FUNCTION update_room_status();

--+ Khach hang chi duoc dung 1 voucher tren 1 don booking
CREATE OR REPLACE FUNCTION check_voucher_usage()
RETURNS TRIGGER AS $$
DECLARE
  existing_voucher_id INTEGER;
BEGIN
  SELECT voucher_id INTO existing_voucher_id
  FROM include
  WHERE booking_id = NEW.booking_id;

  IF existing_voucher_id IS NOT NULL THEN
    RAISE EXCEPTION 'Don hang da su dung voucher % roi.', existing_voucher_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_voucher_usage_trigger
BEFORE INSERT ON include
FOR EACH ROW
EXECUTE FUNCTION check_voucher_usage();

