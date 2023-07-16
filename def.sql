CREATE TABLE supplier (
    supplier_id char(8) NOT NULL,
    name varchar(20) NOT NULL,
    address varchar(50),
    email varchar(30),
    CONSTRAINT supplier_pk PRIMARY KEY (supplier_id)
);

CREATE TABLE furniture(
    fur_id char(8) NOT NULL,
    name varchar(20) NOT NULL,
    num_in_stock int NOT NULL,
    num_in_use int NOT NULL,
    description varchar(200),
    CONSTRAINT fur_pk PRIMARY KEY (fur_id)
);

CREATE TABLE supply(
    sup_id char(8) NOT NULL,
    supplier_id char(8) NOT NULL,
    fur_id char(8) NOT NULL, 
    num_in_order int NOT NULL,
    price_per_unit money,
    time date NOT NULL,
    CONSTRAINT supply_pk PRIMARY KEY (sup_id)
);

CREATE TABLE room(
    room_id char(8) NOT NULL,
    number char(3) NOT NULL,
    description varchar(200),
    status char(1) NOT NULL,
    price money NOT NULL,
    CONSTRAINT room_pk PRIMARY KEY (room_id)
);

CREATE TABLE decor(
    room_id char(8) NOT NULL,
    fur_id char(8) NOT NULL,
    number int NOT NULL, 
    num_broken int NOT NULL,
    description varchar(200),
    CONSTRAINT decor_pk PRIMARY KEY (room_id, fur_id)
);

CREATE TABLE category(
    cat_id char(8) NOT NULL,
    tangname varchar(30) NOT NULL,
    description varchar(200),
    color varchar(10) NOT NULL,
    CONSTRAINT cat_pk PRIMARY KEY (cat_id)
);

CREATE TABLE tag(
    room_id char(8) NOT NULL,
    cat_id char(8) NOT NULL,
    CONSTRAINT tag_pk PRIMARY KEY (room_id, cat_id)
);

CREATE TABLE service(
    service_id char(8) NOT NULL,
    name varchar(20) NOT NULL,
    description varchar(200),
    price money NOT NULL,
    CONSTRAINT service_pk PRIMARY KEY (service_id)
);

CREATE TABLE include(
    room_id char(8) NOT NULL,
    service_id char(8) NOT NULL,
    status char(1) NOT NULL, 
    CONSTRAINT include_pk PRIMARY KEY (room_id, service_id)
);

------------------------------------------------------------

CREATE TABLE customer_type(
    type_id char(8) NOT NULL,
    condition varchar(200),
    name varchar(20) NOT NULL,
    CONSTRAINT customer_type_pk PRIMARY KEY (type_id)
);

CREATE TABLE voucher(
    voucher_id char(8) NOT NULL,
    name varchar(20) NOT NULL,
    num int NOT NULL,
    percentage float NOT NULL,
    starting_date date NOT NULL,
    expiry_date date NOT NULL,
    description varchar(200),
    CONSTRAINT voucher_pk PRIMARY KEY (voucher_id)
);

CREATE TABLE customer (
    leader_id char(8) NOT NULL,
    type_id char(8) NOT NULL,
    cus_id char(8) NOT NULL,
	first_name varchar(20) NOT NULL,
	last_name varchar(20),
	dob date,
	gender char(1),
	email char(30) NOT NULL,
    number varchar(15) NOT NULL,
	check_in_status char(1) NOT NULL,
	check_out_status char(1) NOT NULL,
    check_in_time date NOT NULL,
    check_out_time date NOT NULL,
    check_in_method char(10) NOT NULL,
    groupname varchar(30),
    CONSTRAINT customer_pk PRIMARY KEY (cus_id)
);

CREATE TABLE apply(
    cus_id char(8) NOT NULL,
    voucher_id char(8) NOT NULL,
    status char(1) NOT NULL,
    CONSTRAINT apply_pk PRIMARY KEY (cus_id, voucher_id)
);

CREATE TABLE booking(
    cus_id char(8) NOT NULL,
    booking_id char(8) NOT NULL,
    status char(1) NOT NULL,
    time date NOT NULL,
    feedback varchar(200),
    total_price money NOT NULL,
    payment_method varchar(20) NOT NULL, 
    CONSTRAINT booking_pk PRIMARY KEY (booking_id)
);

CREATE TABLE booking_line(
    booking_id char(8) NOT NULL,
    room_id char(8) NOT NULL,
    lenghth_of_stay int NOT NULL,
    price money NOT NULL,
    time date NOT NULL,
    check_in_date date NOT NULL,
    CONSTRAINT booking_line_pk PRIMARY KEY (booking_id, room_id)
);

---------------------

ALTER TABLE supply
ADD CONSTRAINT suppy_fk_suppr FOREIGN KEY (supplier_id)
REFERENCES supplier(supplier_id);

ALTER TABLE supply
ADD CONSTRAINT suppy_fk_fur FOREIGN KEY (fur_id)
REFERENCES furniture(fur_id);

ALTER TABLE tag
ADD CONSTRAINT tag_fk_room FOREIGN KEY (room_id)
REFERENCES room(room_id);

ALTER TABLE tag
ADD CONSTRAINT tag_fk_cat FOREIGN KEY (cat_id)
REFERENCES category(cat_id);

ALTER TABLE decor
ADD CONSTRAINT decor_fk_room FOREIGN KEY (room_id)
REFERENCES room(room_id);

ALTER TABLE decor
ADD CONSTRAINT decor_fk_furniture FOREIGN KEY (fur_id)
REFERENCES furniture(fur_id);

-----------------------
ALTER TABLE customer
ADD CONSTRAINT cus_fk_cus_type FOREIGN KEY (type_id)
REFERENCES customer_type(type_id);

ALTER TABLE customer
ADD CONSTRAINT cus_fk_cus FOREIGN KEY (leader_id)
REFERENCES customer(cus_id);

ALTER TABLE apply
ADD CONSTRAINT app_fk_cus FOREIGN KEY (cus_id)
REFERENCES customer(cus_id);

ALTER TABLE apply
ADD CONSTRAINT app_fk_voucher FOREIGN KEY (voucher_id)
REFERENCES voucher(voucher_id);

ALTER TABLE booking
ADD CONSTRAINT booking_fk_cus FOREIGN KEY (cus_id)
REFERENCES customer(cus_id);

ALTER TABLE booking_line
ADD CONSTRAINT bookingl_fk_booking FOREIGN KEY (booking_id)
REFERENCES booking(booking_id);

ALTER TABLE booking_line
ADD CONSTRAINT bookingl_fk_room FOREIGN KEY (room_id)
REFERENCES room(room_id);

