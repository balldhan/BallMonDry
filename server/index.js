const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const app = express();


app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '', 
    database: 'smartlaundry_db'
});

db.connect((err) => {
    if (err) throw err;
    console.log('Database Connected!');
});

// --- AUTH & USER ---

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

app.post('/register', (req, res) => {
    // Tambahkan latitude dan longitude di req.body
    const { username, password, alamat, latitude, longitude } = req.body;
    
    if (!username || !password || !alamat) {
        return res.status(400).json({ message: 'Semua kolom wajib diisi!' });
    }

    const sql = "INSERT INTO users (username, password, role, alamat, latitude, longitude) VALUES (?, ?, 'client', ?, ?, ?)";
    
    db.query(sql, [username, password, alamat, latitude, longitude], (err, result) => {
        if (err) {
            if (err.code === 'ER_DUP_ENTRY') return res.status(400).json({ message: 'Username sudah ada!' });
            return res.status(500).json({ message: 'Gagal daftar', detail: err.sqlMessage });
        }
        res.json({ status: 'success', message: 'Akun berhasil dibuat' });
    });
});

app.get('/users/:id', (req, res) => {
    const sql = "SELECT id, username, password, alamat, no_hp, latitude, longitude FROM users WHERE id = ?";
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        if (result.length === 0) return res.status(404).json({ message: 'User tidak ditemukan' });
        res.json(result[0]); 
    });
});

app.put('/user/update', (req, res) => {
    const { id, username, password, alamat, no_hp, latitude, longitude } = req.body;
    const sql = "UPDATE users SET username = ?, password = ?, alamat = ?, no_hp = ?, latitude = ?, longitude = ? WHERE id = ?";
    db.query(sql, [username, password, alamat, no_hp, latitude, longitude, id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ status: 'success', message: 'Profil diperbarui' });
    });
});

// --- ORDER & LAYANAN ---

app.get('/layanan', (req, res) => {
    db.query("SELECT * FROM layanan", (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

app.post('/order', (req, res) => {
    const { user_id, layanan_id } = req.body;
    const sql = "INSERT INTO orders (user_id, layanan_id, berat, total_harga, status, tgl_order) VALUES (?, ?, 0, 0, 'dijemput', NOW())";
    db.query(sql, [user_id, layanan_id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ status: 'success', message: 'Order berhasil' });
    });
});

app.get('/history/:user_id', (req, res) => {
    const sql = `SELECT orders.*, layanan.nama_layanan FROM orders 
                 JOIN layanan ON orders.layanan_id = layanan.id 
                 WHERE orders.user_id = ? ORDER BY orders.tgl_order DESC`;
    db.query(sql, [req.params.user_id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// --- ADMIN FEATURES ---

app.get('/orders', (req, res) => {
    const sql = `SELECT orders.*, users.username, layanan.nama_layanan FROM orders
                 JOIN users ON orders.user_id = users.id
                 JOIN layanan ON orders.layanan_id = layanan.id
                 ORDER BY orders.id DESC`;
    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

app.get('/admin/stats', (req, res) => {
    const sql = `SELECT 
            COALESCE(SUM(CASE WHEN status = 'selesai' THEN total_harga ELSE 0 END), 0) as total_pendapatan,
            COUNT(*) as total_order,
            SUM(CASE WHEN status = 'selesai' THEN 1 ELSE 0 END) as order_selesai,
            SUM(CASE WHEN status = 'proses' THEN 1 ELSE 0 END) as order_proses
        FROM orders`;
    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result[0]);
    });
});

app.put('/order/update', (req, res) => {
    const { order_id, status, berat, estimasi } = req.body;
    const sqlGet = "SELECT harga_per_kg FROM orders JOIN layanan ON orders.layanan_id = layanan.id WHERE orders.id = ?";
    db.query(sqlGet, [order_id], (err, results) => {
        if (err || results.length === 0) return res.status(500).json({message: 'Gagal'});
        const total = berat * results[0].harga_per_kg;
        const sqlUpdate = "UPDATE orders SET status = ?, berat = ?, total_harga = ?, estimasi = ? WHERE id = ?";
        db.query(sqlUpdate, [status, berat, total, estimasi, order_id], (errUp) => {
            if (errUp) return res.status(500).json(errUp);
            res.json({ status: 'success' });
        });
    });
});

app.listen(3000, () => console.log('Server BallMonDry running on port 3000'));