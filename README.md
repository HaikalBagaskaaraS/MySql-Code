# 🛒 Minimarket Database Project

Desain dan implementasi sistem database relasional untuk kebutuhan operasional **minimarket** menggunakan **MySQL**. Project ini mencakup perancangan ERD, normalisasi hingga 3NF, pembuatan tabel, serta penerapan **stored procedure** dan **trigger**.

---

## 📌 Deskripsi Singkat

Project ini dibuat sebagai tugas dari CEP-CCIT FTUI untuk menyusun sistem database yang mampu mencatat data pelanggan, karyawan, produk, transaksi, dan detail transaksi secara lengkap dan terintegrasi.

---

## 🧱 Struktur Database

Tabel yang digunakan:
- `customer`
- `employee`
- `product`
- `transaction`
- `transaction_detail`

Desain ini mendukung proses transaksi ritel dengan efisien dan minim redudansi.

---

## 🧠 Fitur Implementasi

✅ Normalisasi hingga **3NF**  
✅ Desain **Entity Relationship Diagram (ERD)**  
✅ **Stored Procedure**:
- Perhitungan total pembayaran
- Otomatisasi insert data transaksi
- Insert data detail transaksi

✅ **Trigger**:
- Validasi data sebelum insert transaksi
- Update stok produk setelah pembelian

---

## 🛠️ Tools & Teknologi

- MySQL Workbench
- MySQL Server
- Spreadsheet (untuk dokumentasi normalisasi)

---

## ▶️ Cara Menjalankan

### 1. Clone repository ini:
```
git clone https://github.com/HaikalBagaskaaraS/MySql-Code.git
cd minimarket-database
```

### 2. Import file SQL ke MySQL Workbench atau tool lain yang kamu gunakan:
minimarket_schema.sql
stored_procedures.sql
triggers.sql

Jalankan perintah-perintah SQL tersebut secara berurutan untuk membentuk struktur database dan logika otomatisasi.

---

Project ini disusun pada Desember 2024 sebagai tugas final Database Project CEP-CCIT FTUI.
