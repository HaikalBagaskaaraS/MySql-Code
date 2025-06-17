-- Create Database
create database db_minimarket_system;
use db_minimarket_system;
drop database db_minimarket_system;






-- Create Table
create table customers (
	cust_id varchar(5) not null,
    name varchar(50),
    phone varchar(15),
    gender enum('Men', 'Women') not null,
    address varchar(100),
    primary key (cust_id)
) engine=InnoDB;

create table employees (
	employee_id varchar(5) not null,
    name varchar(50) not null,
    role varchar(20) not null,
    phone varchar(15) not null,
    address varchar(100) not null,
    primary key (employee_id)
) engine=InnoDB;

create table products (
	product_id varchar(5) not null,
    name varchar(50) not null,
    category varchar(25) not null,
    price int not null,
    stock int not null,
    primary key (product_id)
) engine=InnoDB;

create table transactions (
	transaction_id varchar(5) not null,
    cust_id varchar(5) not null,
    employee_id varchar(5) not null,
    date datetime default current_timestamp,
    total_quantity int not null,
    total_payment int not null,
    payment_method varchar(50) not null,
    primary key (transaction_id),
    constraint fk_cust_id foreign key (cust_id) references customers (cust_id),
    constraint fk_employee_id foreign key (employee_id) references employees (employee_id)
) engine=InnoDB;

create table transaction_details (
	transaction_id varchar(5) not null,
    product_id varchar(5) not null,
    price int not null,
    quantity int not null,
    total_price int not null,
    constraint fk_transaction_id foreign key (transaction_id) references transactions (transaction_id),
    constraint fk_product_id foreign key (product_id) references products (product_id)
)  engine=InnoDB;






-- Create Index & FullTextIndex
alter table products
add index idx_name (name);

alter table products
add fulltext index ft_idx_name (name);





-- insert data with insert into
insert into customers (cust_id, name, phone, gender, address)
values	('C0001', 'John', '087656574322', 'Men', 'Jakarta Selatan');

insert into employees (employee_id, name, role, phone, address)
values	('E0001', 'Mikael', 'Supervisior', '087865435687', 'Jakarta Pusat'),
		('E0002', 'Nisa', 'Kasir', '082176654322', 'Jakarta Selatan'),
        ('E0003', 'Asep', 'Kasir', '085886810876', 'Depok'),
        ('E0004', 'Anna', 'Kasir', '084567876556', 'Jakarta Selatan'),
        ('E0005', 'Deden', 'Kasir', '0087645233344', 'Bekasi');

insert into products (product_id, name, category, price, stock)
values	('P0001', 'Mie Instan', 'Makanan', 3000, 100),
		('P0002', 'Air Mineral', 'Minuman', 5000, 150);





-- Create Prosedure add transaction
DELIMITER //
create procedure proc_AddTransaction (
    in p_transaction_id varchar(5),
    in p_cust_id varchar(5),
    in p_employee_id varchar(5),
    in p_payment_method varchar(50),
    in p_product_ids text, -- Format: 'P0001,P0002'
    in p_quantities text   -- Format: '2,1'
)
BEGIN
    declare current_product_id varchar(10); 
    declare current_quantity int;
    declare current_price int;
    declare current_stock int;
    declare total_price int;
    declare total_quantity int default 0;
    declare total_payment int default 0;
    
    -- Simpan salinan awal p_product_ids dan p_quantities
    declare original_product_ids text default p_product_ids;
    declare original_quantities text default p_quantities;
    
    -- Loop untuk validasi produk dan stok sebelum insert ke tabel transactions
    while length(p_product_ids) > 0 DO
        -- Ambil produk pertama dan jumlahnya
        set current_product_id = SUBSTRING_INDEX(p_product_ids, ',', 1);
        set current_quantity = CAST(SUBSTRING_INDEX(p_quantities, ',', 1) as unsigned);

        -- Potong produk dan jumlah yang telah diproses
        set p_product_ids = if(LENGTH(p_product_ids) = LENGTH(current_product_id), '', 
                               SUBSTRING(p_product_ids, LENGTH(current_product_id) + 2));
        set p_quantities = if(LENGTH(p_quantities) = LENGTH(SUBSTRING_INDEX(p_quantities, ',', 1)), '', 
                              SUBSTRING(p_quantities, LENGTH(SUBSTRING_INDEX(p_quantities, ',', 1)) + 2));

        -- Ambil harga dan stok produk
        select price, stock into current_price, current_stock
        from products 
        where product_id = current_product_id;

        -- Validasi apakah produk ditemukan
        if current_price is null then
            set @error_message = CONCAT('Product ID not found: ', current_product_id);
            signal sqlstate '45000'
            set message_text = @error_message;
        end if;

        -- Validasi apakah stok mencukupi
        if current_stock < current_quantity then
            set @error_message = CONCAT('Insufficient stock for product ID: ', current_product_id, 
                                        '. Available stock: ', current_stock);
            signal sqlstate '45000'
            set message_text = @error_message;
        end if;

        -- Update total quantity dan payment sementara
        set total_quantity = total_quantity + current_quantity;
        set total_payment = total_payment + (current_price * current_quantity);
    end while;

    -- Jika total_quantity = 0 setelah validasi semua produk
    if total_quantity = 0 then
        signal sqlstate '45000'
        set message_text = 'Transaction failed: no valid products or insufficient stock.';
    end if;

    -- Insert ke tabel transactions setelah validasi
    insert into transactions (transaction_id, cust_id, employee_id, total_quantity, total_payment, payment_method)
    values (p_transaction_id, p_cust_id, p_employee_id, 0, 0, p_payment_method);

    -- Gunakan kembali salinan asli untuk loop kedua
    set p_product_ids = original_product_ids;
    set p_quantities = original_quantities;

    -- Loop kedua untuk memasukkan detail transaksi
    while LENGTH(p_product_ids) > 0 do
        -- Ambil produk pertama dan jumlahnya
        set current_product_id = SUBSTRING_INDEX(p_product_ids, ',', 1);
        set current_quantity = CAST(SUBSTRING_INDEX(p_quantities, ',', 1) as unsigned);

        -- Potong produk dan jumlah yang telah diproses
        set p_product_ids = if(LENGTH(p_product_ids) = LENGTH(current_product_id), '', 
                               SUBSTRING(p_product_ids, LENGTH(current_product_id) + 2));
        set p_quantities = if(LENGTH(p_quantities) = LENGTH(SUBSTRING_INDEX(p_quantities, ',', 1)), '', 
                              SUBSTRING(p_quantities, LENGTH(SUBSTRING_INDEX(p_quantities, ',', 1)) + 2));

        -- Ambil harga produk
        select price into current_price
        from products 
        where product_id = current_product_id;

        -- Hitung total harga
        set total_price = current_price * current_quantity;

        -- Masukkan ke tabel transaction_details
        insert into transaction_details (transaction_id, product_id, price, quantity, total_price)
        values (p_transaction_id, current_product_id, current_price, current_quantity, total_price);

        -- Update stok produk
        update products
        set stock = stock - current_quantity
        where product_id = current_product_id;
    end while;

    -- Update tabel transactions dengan total quantity dan payment
    update transactions 
    set total_quantity = total_quantity, total_payment = total_payment
    where transaction_id = p_transaction_id;
END //
DELIMITER ;

-- Create Procedure Add Product
DELIMITER $$
create procedure proc_AddProduct(
	in p_product_id varchar(5),
    in p_name varchar(50),
    in p_category varchar(25),
    in p_price int,
    in p_stock int
)
BEGIN
    -- 1. Validasi apakah ID produk sudah ada
    if exists (select 1 from products where product_id = p_product_id) then
        signal sqlstate '45000' set message_text = 'Produk dengan ID tersebut sudah ada.';
    end if;

    -- 2. Validasi apakah nama produk sudah ada
    if exists (select 1 from products where name = p_name) then
        signal sqlstate '45000' set message_text = 'Produk dengan nama tersebut sudah ada.';
    end if;

    -- 3. Validasi apakah stok produk valid (tidak kosong atau negatif)
    if p_stock <= 0 then
        signal sqlstate '45000' set message_text = 'Stok produk tidak boleh kosong atau negatif.';
    end if;

    -- 4. Validasi apakah harga produk valid (tidak negatif)
    if p_price <= 0 then
        signal sqlstate '45000' set message_text = 'Harga produk tidak boleh negatif.';
    end if;

    -- Menambahkan produk jika tidak ada error
    insert into products (product_id, name, category, price, stock)
    values (p_product_id, p_name, p_category, p_price, p_stock);
END $$
DELIMITER ;

-- Create Procedure Add Stock Product
DELIMITER ++
create procedure proc_AddStock(
    in p_product_id varchar(5),
    in p_add_stock int
)
BEGIN
    -- 1. Validasi apakah ID produk ada dalam tabel products
    if not exists (select 1 from products where product_id = p_product_id) then
        signal sqlstate '45000' set message_text = 'Produk dengan ID tersebut tidak ditemukan.';
    end if;

    -- 2. Validasi apakah jumlah stok yang akan ditambahkan valid (tidak negatif atau kosong)
    IF p_add_stock <= 0 THEN
        signal sqlstate '45000' set message_text = 'Jumlah stok yang ditambahkan tidak boleh kosong atau negatif.';
    end if;

    -- 3. Menambahkan stok ke produk yang valid
    update products
    set stock = stock + p_add_stock
    where product_id = p_product_id;
END ++
DELIMITER ;

-- Create Procedure Add Cust
DELIMITER \\
create procedure proc_AddCustomer(
    in p_cust_id varchar(5),
    in p_name varchar(50),
    in p_phone varchar(15),
    in p_gender enum('Men', 'Women'),
    in p_address varchar(100)
)
BEGIN
    -- 1. Validasi apakah ID pelanggan sudah ada
    if exists (select 1 from customers where cust_id = p_cust_id) then
        signal sqlstate '45000' set message_text = 'ID pelanggan sudah digunakan.';
    end if;

    -- 2. Validasi apakah nama pelanggan sudah ada
    if exists (select 1 from customers where name = p_name) then
        signal sqlstate '45000' set message_text = 'Nama pelanggan sudah digunakan.';
    end if;

    -- 3. Validasi apakah nomor telepon pelanggan sudah ada
    if exists (select 1 from customers where phone = p_phone) then
        signal sqlstate '45000' set message_text = 'Nomor telepon pelanggan sudah digunakan.';
    end if;

    -- 4. Validasi apakah gender sesuai dengan nilai yang diperbolehkan
    if p_gender not in ('Men', 'Women') then
        signal sqlstate '45000' set message_text= 'Gender hanya boleh Men atau Women.';
    end if;

    -- 5. Menambahkan pelanggan baru ke tabel customers
    insert into customers (cust_id, name, phone, gender, address)
    values (p_cust_id, p_name, p_phone, p_gender, p_address);
END \\
DELIMITER ;





-- Create Trigger
DELIMITER |
-- Trigger untuk menghitung ulang total transaksi setelah INSERT pada transaction_details
create trigger trg_UpdateTransactionTotals
after insert on transaction_details
for each row
BEGIN
    declare calculated_quantity int default 0;
    declare calculated_payment int default 0;

    -- Hitung ulang total kuantitas dan pembayaran
    select SUM(quantity), SUM(total_price)
    into calculated_quantity, calculated_payment
    from transaction_details
    where transaction_id = new.transaction_id;

    -- Update tabel transactions
    update transactions
    set total_quantity = calculated_quantity, total_payment = calculated_payment
    where transaction_id = new.transaction_id;
END |
DELIMITER ;

DELIMITER ||
-- Trigger untuk validasi data transaksi sebelum INSERT pada transactions
create trigger trg_ValidateTransactionData
before insert on transactions
for each row
BEGIN
    -- Validasi ID transaksi
    if CHAR_LENGTH(NEW.transaction_id) != 5 then
        signal sqlstate '45000' set message_text = 'Format ID transaksi tidak valid (harus 5 karakter).';
    end if;

    -- Validasi ID pelanggan
    if not exists (select 1 from customers where cust_id = new.cust_id) then
        signal sqlstate '45000' set message_text = 'ID pelanggan tidak ditemukan.';
    end if;

    -- Validasi ID karyawan
    if not exists (select 1 from employees where employee_id = new.employee_id) then
        signal sqlstate '45000' set message_text = 'ID karyawan tidak ditemukan.';
    end if;

    -- Validasi total pembayaran
    if new.total_payment < 0 then
        signal sqlstate '45000' set message_text = 'Total pembayaran tidak boleh negatif.';
    end if;
END ||
DELIMITER ;





-- view data in table
select * from Customers;
select * from Employees;
select * from Products;
select * from Transactions;
select * from transaction_details;

create view vw_nota_TransactionDetails as
select	t.transaction_id as `Kode Transaksi`,
		c.name as `Nama Pembeli`,
        t.date as `Tanggal Transaksi`,
        dt.product_id as `Kode Product`,
        p.name as `Nama Product`,
        p.price as `Harga Product`,
        dt.quantity as `Jumlah Product`,
        t.total_payment as `Total Harga`,
        e.name as `Nama Yang Melayani`,
        e.role as `Jabatan` from transactions t
join customers c on c.cust_id = t.cust_id
join employees e on e.employee_id = t.employee_id
join transaction_details dt on dt.transaction_id = t.transaction_id
join products  p on p.product_id = dt.product_id;

create view vw_DataPenjualanProduct as
select	p.product_id as 'Kode Product',
		p.name as 'Nama Product',
        p.price as 'Harga Product',
        sum(dt.quantity) as 'Jumlah Terjual',
        sum(dt.quantity * dt.price) as 'Total Penjualan' from products p
join transaction_details dt on dt.product_id = p.product_id
group by p.product_id, p.name, p.price;

create view vw_DataPenjualanPerhari as
select	date(t.date) as 'Tanggal Tranasaksi',
		count(t.transaction_id) as 'Jumlah Transaksi',
        sum(t.total_quantity) as 'Jumlah Product Terjual',
        sum(t.total_payment) as 'Total Pendapatan' from transactions t
group by date(t.date) order by 'Tanggal Tranasaksi';





-- Pengujian
CALL proc_AddTransaction('T0001', 'C0001', 'E0001', 'Cash', 'P0001,P0002', '2,1');

CALL proc_AddProduct('P0003', 'Susu UHT', 'Minuman', 12000, 50);
CALL proc_AddProduct('P0004', 'Tisu Gulung', 'Produk Rumah Tangga', 4000, 10);
CALL proc_AddProduct('P0005', 'Keripik Singkong', 'Makanan', 5000, 30);
CALL proc_AddProduct('P0006', 'Coklat', 'Makanan', 9000, 50);
CALL proc_AddProduct('P0007', 'Biskuit', 'Makanan', 7000, 15);
CALL proc_AddProduct('P0008', 'Popcorn', 'Makanan', 12000, 20);
CALL proc_AddProduct('P0009', 'Pocari', 'Minuman', 6000, 70);
CALL proc_AddProduct('P0010', 'Coca Cola', 'Minuman', 5000, 100);
CALL proc_AddProduct('P0011', 'Teh Kotak', 'Minuman', 7000, 70);
CALL proc_AddProduct('P0012', 'Pembersih Lantai', 'Produk Rumah Tangga', 8000, 40);
CALL proc_AddProduct('P0013', 'Sabun Mandi', 'Produk Rumah Tangga', 4000, 50);
CALL proc_AddProduct('P0014', 'Sabun Cuci Piring', 'Produk Rumah Tangga', 12000, 45);
CALL proc_AddProduct('P0015', 'Shampo Botol', 'Produk Rumah Tangga', 18000, 25);
CALL proc_AddProduct('P0016', 'Pasta Gigi', 'Produk Rumah Tangga', 12000, 45);
CALL proc_AddProduct('P0017', 'Vitamin C', 'Obat dan Kesehatan', 19000, 20);
CALL proc_AddProduct('P0018', 'Paracetamol', 'Obat dan Kesehatan', 12000, 15);
CALL proc_AddProduct('P0019', 'Minyak Kayu Putih', 'Obat dan Kesehatan', 11000, 25);
CALL proc_AddProduct('P0020', 'Kopi Kaleng', 'Minuman', 10000, 110);

CALL proc_AddStock('P0004', 10);
CALL proc_AddStock('P0018', 3);

CALL proc_AddCustomer('C0002', 'Nana', '087665543212', 'Women', 'Bogor');
CALL proc_AddCustomer('C0003', 'Dede', '089765431122', 'Men', 'Jakarta Selatan');
CALL proc_AddTransaction('T0002', 'C0002', 'E0002', 'Debit', 'P0001,P0002,P0004', '3,4,5');
CALL proc_AddTransaction('T0003', 'C0003', 'E0002', 'Qris', 'P0002', '5');
-- yg bawah uji di hari berikutnya
CALL proc_AddCustomer('C0004', 'Dodi', '087654321155', 'Men', 'Jakarta Barat');
CALL proc_AddCustomer('C0005', 'Keke', '087123321785', 'Women', 'Jakarta Selatan');
CALL proc_AddTransaction('T0004', 'C0004', 'E0004', 'Cash', 'P0001,P0009,P0005', '5,2,5');
CALL proc_AddTransaction('T0005', 'C0005', 'E0004', 'Qris', 'P0002', '5');

CALL proc_AddTransaction('T0006', 'C0001', 'E0004', 'Debit', 'P0001,P0009', '3,2');

select * from products where match(name) 
against('sabun' in natural language mode);

select * from vw_DataPenjualanProduct;
select * from vw_DataPenjualanPerhari;
select * from vw_nota_TransactionDetails;
select * from vw_nota_TransactionDetails where `Kode Transaksi` = 'T0002';




        
        
        