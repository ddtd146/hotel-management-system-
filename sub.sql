CREATE FUNCTION fnc_calculate_total_money(in bookingid INTEGER) RETURNS money AS 
$$
DECLARE
  total MONEY;
  line RECORD;
BEGIN
  total = 0;
  for line in (SELECT room_id, l.length_of_stay, r.price INTO id, los, price_per_night FROM booking b
  JOIN booking_line l USING (bookin_id)
  JOIN room USING (room_id))
  loop
    UPDATE booking_line 
    SET price = line.los * line.price_per_night
    WHERE room_id = id;
    total += line.los * line.price_per_night
  end loop;
  UPDATE booking 
  SET total_price = total 
  WHERE booking_id = bookingid;
END;
$$
LANGUAGE plpgsql;