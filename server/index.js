const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// --- KONEKSI DATABASE ---
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '', 
    database: 'smartlaundry_db' // Pastikan sama dengan nama DB kamu
});

db.connect((err) => {
    if (err) throw err;
    console.log('Database Connected!');
});

// --- API ENDPOINTS ---

// 1. LOGIN (Cek User apakah Admin atau Client)
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    const sql = "SELECT * FROM users WHERE username = ? AND password = ?";
    db.query(sql, [username, password], (err, result) => {
        if (err) return res.status(500).json(err);
        if (result.length > 0) {
            res.json({ status: 'success', data: result[0] });
        } else {
            res.status(401).json({ status: 'fail', message: 'Username/Password salah' });
        }
    });
});

// 2. GET LAYANAN (Supaya Client bisa pilih mau Cuci Kering/Setrika)
app.get('/layanan', (req, res) => {
    const sql = "SELECT * FROM layanan";
    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// 3. CLIENT: REQUEST PICKUP (Buat Order Baru)
// Client cuma kirim user_id dan layanan_id. Berat masih 0 karena belum ditimbang.
// 3. CLIENT: REQUEST PICKUP (DEBUG MODE ON)
app.post('/order', (req, res) => {
    const { user_id, layanan_id } = req.body;
    
    console.log("Coba Insert -> User:", user_id, " Layanan:", layanan_id);

    const sql = `
        INSERT INTO orders 
        (user_id, layanan_id, berat, total_harga, status, tgl_order) 
        VALUES (?, ?, 0, 0, 'dijemput', NOW())
    `;

    db.query(sql, [user_id, layanan_id], (err, result) => {
        if (err) {
            // INI KUNCINYA: Kita kirim pesan error asli MySQL ke HP
            console.error("ERROR SQL:", err.sqlMessage); 
            return res.status(500).json({ 
                status: 'error',
                message: 'Database Menolak!',
                detail: err.sqlMessage // Ini nanti muncul di HP
            });
        }
        res.json({ status: 'success', message: 'Kurir segera meluncur!' });
    });
});

// 4. ADMIN: LIHAT SEMUA ORDER
app.get('/orders', (req, res) => {
    // PERBAIKAN: Tambahkan 'orders.estimasi' di baris bawah ini 👇
    const sql = `
        SELECT orders.id, users.username, layanan.nama_layanan, 
               orders.berat, orders.total_harga, orders.status, orders.estimasi 
        FROM orders
        JOIN users ON orders.user_id = users.id
        JOIN layanan ON orders.layanan_id = layanan.id
        ORDER BY orders.id DESC
    `;
    
    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// 5. ADMIN: PROSES TIMBANGAN & HITUNG HARGA (Logic Inti Soal)
app.put('/order/process', (req, res) => {
    const { order_id, berat } = req.body;

    // Langkah 1: Ambil harga per kg dari database berdasarkan order_id
    const sqlGetHarga = `
        SELECT layanan.harga_per_kg 
        FROM orders 
        JOIN layanan ON orders.layanan_id = layanan.id 
        WHERE orders.id = ?
    `;

    db.query(sqlGetHarga, [order_id], (err, result) => {
        if (err) return res.status(500).json(err);
        if (result.length === 0) return res.status(404).json({message: 'Order not found'});

        const hargaPerKg = result[0].harga_per_kg;
        
        // --- OPERASI PERHITUNGAN DISINI ---
        const totalBayar = berat * hargaPerKg; 
        
        // Langkah 2: Update Database dengan hasil hitungan
        const sqlUpdate = "UPDATE orders SET berat = ?, total_harga = ?, status = 'proses' WHERE id = ?";
        db.query(sqlUpdate, [berat, totalBayar, order_id], (err, updateResult) => {
            if (err) return res.status(500).json(err);
            res.json({ 
                status: 'success', 
                message: 'Order diproses', 
                detail: { berat: berat, total: totalBayar } 
            });
        });
    });
});

// 6. CLIENT: LIHAT RIWAYAT SENDIRI
app.get('/history/:user_id', (req, res) => {
    const userId = req.params.user_id;
    // PERBAIKAN: Tambahkan 'orders.estimasi' di baris bawah ini 👇
    const sql = `
        SELECT orders.id, layanan.nama_layanan, orders.status, orders.total_harga, orders.tgl_order, orders.estimasi 
        FROM orders
        JOIN layanan ON orders.layanan_id = layanan.id
        WHERE orders.user_id = ?
        ORDER BY orders.tgl_order DESC
    `;
    db.query(sql, [userId], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// 7. REGISTER USER BARU (Default Role: Client)
app.post('/register', (req, res) => {
    const { username, password, alamat } = req.body;
    
    // Validasi sederhana
    if (!username || !password || !alamat) {
        return res.status(400).json({ message: 'Semua kolom wajib diisi!' });
    }

    // Default role kita set 'client' biar aman.
    const sql = "INSERT INTO users (username, password, role, alamat) VALUES (?, ?, 'client', ?)";
    
    db.query(sql, [username, password, alamat], (err, result) => {
        if (err) {
            // Cek kalau username sudah ada (Duplicate)
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(400).json({ message: 'Username sudah dipakai orang lain!' });
            }
            return res.status(500).json({ message: 'Gagal daftar', detail: err.sqlMessage });
        }
        res.json({ status: 'success', message: 'Hore! Akun berhasil dibuat.' });
    });
});

// 8. ADMIN: UPDATE ORDER LENGKAP (Status, Berat, Estimasi)
app.put('/order/update', (req, res) => {
    const { order_id, status, berat, estimasi } = req.body;
    
    // Ambil dulu harga layanan buat hitung total ulang (kalau berat berubah)
    const sqlGet = "SELECT layanan.harga_per_kg FROM orders JOIN layanan ON orders.layanan_id = layanan.id WHERE orders.id = ?";
    
    db.query(sqlGet, [order_id], (err, results) => {
        if (err) return res.status(500).json(err);
        if (results.length === 0) return res.status(404).json({message: 'Order hilang'});

        let hargaPerKg = results[0].harga_per_kg;
        let total = 0;
        
        // Logika update dinamis
        let query = "UPDATE orders SET status = ?, estimasi = ?";
        let params = [status, estimasi];

        // Kalau Admin masukin berat, kita update total harganya juga
        if (berat && berat > 0) {
            total = berat * hargaPerKg;
            query += ", berat = ?, total_harga = ?";
            params.push(berat, total);
        }

        query += " WHERE id = ?";
        params.push(order_id);

        db.query(query, params, (err, result) => {
             if (err) return res.status(500).json(err);
             res.json({status: 'success', message: 'Data order berhasil diupdate!'});
        });
    });
});

app.listen(3000, () => {
    console.log('Server Smart Laundry Ready di Port 3000...');
});