--customer_type
INSERT INTO customer_type (type_id, name) 
	VALUES 
	('00000000', 'Ng binh thuong'),
	('00000001', 'Den deu dan')


--customer
INSERT INTO customer(cus_id, first_name, cccd) VALUES 
	('00000001', 'Dung', '140603'),
	('00000002', 'Dat', '170603'),
	('00000003', 'Dien', '240703'),
	('00000026', 'Huong', '260103')
	('24242424', 'Hai tu', '242424')
--voucher

INSERT INTO voucher(voucher_id, name, num, percentage,description) VALUES ('00000000', 'Cho nguoi moi', -1, 10, 'Luon ap dung cho nguoi moi den lan dau')
INSERT INTO voucher(voucher_id, name, num, percentage) VALUES ('00001000', 'demo', 3, 20)

--apply
