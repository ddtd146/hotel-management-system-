--Nguyen Thanh Dat
--20215028
--

-----Query:

--Dua ra 3 nha cung cap ban nhieu hang nhat cho khach san (tinh theo gia tien)
select name, sum(supply.num_in_order*supply.price_per_unit) as max_money
from supplier
right join supply using (supplier_id)
group by (supplier_id, name)
order by max_money DESC
LIMIT 3;

--Thong ke nhung phong co noi that can sua chua
select room.number, furniture.name, decor.num_broken from room, decor, furniture
where (room.room_id = decor.room_id and decor.fur_id = furniture.fur_id and decor.num_broken > 0);

--Dua cac loai noi that co trong 1 phong bat ky
select room.room_id, room.number as room_number, furniture.name as fur_name, decor.number as fur_number, decor.num_broken
from room, decor, furniture
where ('103' = room.number and room.room_id = decor.room_id and decor.fur_id = furniture.fur_id);


--Function:

--Tinh tong so tien phai chi de mua noi that trong 1 thang bat ky
create or replace function total_money_in_a_month(in moth double precision, out total_money money) AS
$$
begin
    select into total_money sum(supply.num_in_order*supply.price_per_unit) from supply
    where moth = DATE_PART('month', supply.time);
end;
$$
language plpgsql;

--Tinh tong so noi that dang can sua chua
create or replace function fnc_total_fur_broken(out total_num_broken int) AS
$$
begin
    select into total_num_broken sum(num_broken) from decor;
end;
$$
language plpgsql;

--Tinh tong so noi that dang su dung
create or replace function fnc_total_fur_use(out total_num_use int) AS
$$
begin
    select into total_num_use sum(num_in_use) from furniture;
end;
$$
language plpgsql;


--Trigger Function:

--Cap nhat so luong noi that sau khi dat, sua, huy don hang mua noi that (neu noi that da ton tai thi tu dong cap nhat so luong cho no) 
create or replace function tgfnc_af_supply()
returns trigger as
$$
begin
    if (TG_OP = 'INSERT') 
    then
        update furniture
        set num_in_stock = num_in_stock + new.num_in_order
        where furniture.fur_id = new.fur_id;
        return new;

    elsif (TG_OP = 'DELETE') 
    then
        update furniture
        set num_in_stock = num_in_stock - old.num_in_order
        where furniture.fur_id = old.fur_id;
        return old;

    elsif (TG_OP = 'UPDATE') 
    then
        update furniture
        set num_in_stock = num_in_stock + new.num_in_order
        where furniture.fur_id = new.fur_id;

        update furniture
        set num_in_stock = num_in_stock - old.num_in_order
        where furniture.fur_id = old.fur_id;

        return new;
  end if;
  
  return null;
end;
$$
language plpgsql;

create trigger af_in_supply
after insert on supply
for each row
execute procedure tgfnc_af_supply();

create trigger af_de_supply
after delete on supply
for each row
execute procedure tgfnc_af_supply();

create trigger af_up_supply
after update on supply
for each row
execute procedure tgfnc_af_supply();

--Kiem tra so luong noi that truoc khi decor
create or replace function tgfnc_bf_decor()
returns trigger as
$$
declare id_id integer;
begin
    if (TG_OP = 'INSERT') 
    then
        select into id_id num_in_stock from furniture
        where furniture.fur_id = new.fur_id;
        if (new.number > id_id)
        then
            raise Notice 'So luong khong du de decor!';
            return null;
        elsif (new.number < 0)
        then 
            raise Notice 'So luong bi am! Hay nhap lai!';
            return null;
        end if;
        return new;

    elsif (TG_OP = 'UPDATE') 
    then
        select into id_id num_in_stock from furniture
        where furniture.fur_id = new.fur_id;
        if (new.number - old.number > id_id)
        then
            raise Notice 'So luong khong du de decor!';
            return null;
        elsif (new.number < 0)
        then 
            raise Notice 'So luong bi am! Hay nhap lai!';
            return null;
        end if;
        return new;
    end if;
  
    return null;
end;
$$
language plpgsql;

create trigger bf_in_decor
before insert on decor
for each row
execute procedure tgfnc_bf_decor();

create trigger bf_up_decor
before update on decor
for each row
execute procedure tgfnc_bf_decor();

--Cap nhat so luong noi that sau khi decor
create or replace function tgfnc_af_decor()
returns trigger as
$$
begin
    if (TG_OP = 'INSERT') 
    then
        update furniture
        set num_in_stock = num_in_stock - new.number
        where furniture.fur_id = new.fur_id;

        update furniture
        set num_in_use = num_in_use + new.number
        where furniture.fur_id = new.fur_id;

        return new;

    elsif (TG_OP = 'UPDATE') 
    then
        update furniture
        set num_in_stock = num_in_stock - (new.number - old.number)
        where furniture.fur_id = new.fur_id;

        update furniture
        set num_in_use = num_in_use + (new.number - old.number)
        where furniture.fur_id = new.fur_id;

        if(new.num_broken < old.num_broken)
        then    
            update furniture
            set num_in_use = num_in_use - (old.num_broken - new.num_broken)
            where furniture.fur_id = new.fur_id;
        end  if;
        
        return new;
    elsif (TG_OP = 'DELETE')
    then    
        update furniture
        set num_in_stock = num_in_stock + old.number
        where furniture.fur_id = old.fur_id;

        update furniture
        set num_in_use = num_in_use - old.number
        where furniture.fur_id = old.fur_id;
        
        return new;

    end if;
  
    return null;
end;
$$
language plpgsql;

create trigger af_in_decor
after insert on decor
for each row
execute procedure tgfnc_af_decor();

create trigger af_up_decor
after update on decor
for each row
execute procedure tgfnc_af_decor();

create trigger af_de_decor
after delete on decor
for each row
execute procedure tgfnc_af_decor();

--Kiem tra so luong num_broken nhap vao
create or replace function tgfnc_bf_decor_num_broken() returns trigger as
$$
begin
    if (new.num_broken < 0 or new.num_broken > old.number)
    then
        raise Notice 'So luong nhap bi loi, yeu cau nhap lai!';
        return null;
	end if;
    return new;
end;
$$
language plpgsql;

create trigger bf_up_decor_num_broken
before update on decor
for each row
when (new.num_broken is distinct from old.num_broken)
execute procedure tgfnc_bf_decor_num_broken();

--Cap nhat trang thai phong khi co noi that bi hong va sau khi sua chua noi that

create or replace function tgfnc_update_status_room() returns trigger as
$$
declare decor_room_id char(8);
begin
    for decor_room_id in (select room_id  from decor group by room_id having sum(num_broken)>0)
    loop
        update room
        set status = 'X'
        where room.room_id =decor_room_id;
    end loop;

    for decor_room_id in (select room_id  from decor group by room_id having sum(num_broken)=0)
    loop
        update room
        set status = 'E'
        where room.room_id =decor_room_id;
    end loop;
    return new;
end;
$$
language plpgsql;

create trigger af_up_decor_room
after update on decor
for each row
when (new.num_broken is distinct from old.num_broken)
execute procedure tgfnc_update_status_room();

