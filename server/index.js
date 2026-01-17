require('dotenv').config(); // Load environment variables
const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const sharedRoutes = require('./routes/sharedRoutes');
const orderRoutes = require('./routes/orderRoutes');

const app = express();

app.use(cors());
app.use(express.json());

// --- ROUTES DARI CONTROLLER ---
app.use('/admin', sharedRoutes); // Untuk stats
app.use('/orders', orderRoutes); // Untuk manajemen order

// --- DATABASE CONNECTION (LEGACY FOR AUTH) ---
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '', 
    database: 'smartlaundry_db'
});

db.connect((err) => {
    if (err) {
        console.error('Legacy DB Connection Error:', err);
    } else {
        console.log('✅ Main Database Connected!');
    }
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
    const { username, password, alamat } = req.body;
    if (!username || !password || !alamat) return res.status(400).json({ message: 'Lengkapilah data!' });
    const sql = "INSERT INTO users (username, password, role, alamat) VALUES (?, ?, 'client', ?)";
    db.query(sql, [username, password, alamat], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ status: 'success', message: 'User berhasil dibuat' });
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

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server BallMonDry running on port ${PORT}`);
});