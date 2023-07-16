--1. Danh sach phong con trong 
SELECT * FROM room
WHERE status = 'E' 

--2. Danh sach service co the ap dung voi phong 

SELECT * FROM service 
JOIN include USING (service_id)
JOIN room USING (room_id)
WHERE number =  '404'
END;

--3. Danh sach voucher co the ap dung cua khach hang 

SELECT * FROM voucher 
JOIN apply USING (voucher_id)
JOIN customer USING (cus_id)
WHERE customer.first_name = 'Tien Dung' AND customer.last_name = 'Dang'

--4. 

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
  cnt_vch INTEGER;
	cnt_cus INTEGER;
  num_vch INTEGER;
BEGIN
  SELECT count(*) into cnt_vch FROM voucher 
  WHERE voucher_id = voucherid;
  if cnt_vch <= 0 then
    RAISE NOTICE 'Voucher % not found', voucherid;
	return;
  end if;
  SELECT count(*) into cnt_cus FROM customer
  WHERE cus_id = cusid;
  if cnt_cus <= 0 then
    RAISE NOTICE 'Customer % not found', cusid;
	return;
  end if;

  if voucherid <> '00000000' then 
    SELECT num into num_vch FROM voucher 
    WHERE voucher_id = voucherid;
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

--7