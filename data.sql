--customer_type
INSERT INTO customer_type (type_id, name) 
	VALUES 
	('00000000', 'Thanh vien bth'),
	('00001111', 'Nguoi bth'),
	('00000001', 'Den deu dan');


--customer
INSERT INTO customer(cus_id, first_name, cccd) VALUES 
	('00000001', 'Dung', '140603'),
	('00000002', 'Dat', '170603'),
	('00000003', 'Dien', '240703'),
	('00000026', 'Huong', '260103'),
	('24242424', 'Hai tu', '242424'),
	('99998888', 'Nguoi lon', '123456');

INSERT INTO customer(cus_id, first_name) VALUES 
	('66668888', 'Tre Con');
--voucher

INSERT INTO voucher(voucher_id, name, num, percentage,description) VALUES ('00000000', 'Cho nguoi moi', -1, 10, 'Luon ap dung cho nguoi moi den lan dau');
INSERT INTO voucher(voucher_id, name, num, percentage) VALUES ('00001000', 'demo', 3, 20);

--apply

--room 
INSERT INTO room (room_id, number, price) VALUES 
	('00000001', '100', 30), 
	('00000002', '102', 30), 
	('00000003', '103', 30), 
	('00000004', '104', 30);


