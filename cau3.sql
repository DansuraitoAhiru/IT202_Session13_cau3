USE RikkeiClinicDB;

CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);
INSERT INTO Medicines (medicine_id, name, price, stock) 
VALUES
	(1, 'Amoxicillin 500mg', 15000, 100),  -- Tồn kho nhiều
	(2, 'Panadol Extra', 5000, 5);         -- Tồn kho ít


-- Đề xuất cấu trúc bảng Price_Changes_Log
create table Price_Changes_Log (
	log_id int primary key auto_increment,
    medicine_id int not null,
    foreign key(medicine_id) references Medicines(medicine_id),
    old_price decimal(18, 2) not null,
    new_price decimal(18, 2) not null,
    price_status varchar(20) not null,
    difference decimal(18, 2),
	create_at datetime default current_timestamp
);

-- thời điểm kích hoạt Trigger chắc chắn là phải trước khi update thì mới có thể chặn đc giá âm
-- luồng:
-- ktra giá mới nhập có <= 0, nếu có thì chặn và hiện thông báo lỗi
-- else thì sẽ bắt đầu kiểm tra xem nếu giá mới có > giá cũ thì chèn thông tin vào bảng Log với status_price là 'Tăng giá' và lấy độ chênh lệch = giá mới - giá cũ
-- ngược lại giá mới < giá cũ thì cũng chèn thông tin với bảng Log với price_status = 'Giảm giá', độ chênh lệch = giá cũ - giá mới
-- ngoài ra nếu ko thay đổi j thì ko chèn vào log => đơn giản là chỉ cần end if ngay sau khi ktra giá mới < giá cũ là đc

-- code
delimiter //
create trigger saveLog
before update on Medicines
for each row
begin
    if New.price <= 0 then
		signal sqlstate '45000'
        set message_text = 'Lỗi: Giá thuốc mới không hợp lệ';
	else 
		if New.price > Old.price then
			insert into Price_Changes_Log (medicine_id, old_price, new_price, price_status, difference)
            values (New.medicine_id, Old.price, New.price, 'Tăng giá', New.price - Old.price);
		elseif New.price < Old.price then
			insert into Price_Changes_Log (medicine_id, old_price, new_price, price_status, difference)
            values (New.medicine_id, Old.price, New.price, 'Giảm giá', Old.price - New.price);
		end if;
	end if;
end //
delimiter ;
       
-- test
-- tăng giá
update Medicines
set price = 16000
where medicine_id = 1;

-- giảm giá
update Medicines
set price = 4500
where medicine_id = 2;

-- giá ko đổi => ko sinh log
update Medicines
set price = 4500
where medicine_id = 2;

-- nhập giá mới sai => chặn và hiện thông báo
update Medicines
set price = -36000
where medicine_id = 1;

select * from Medicines;
select * from  Price_Changes_Log;
