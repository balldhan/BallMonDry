require('dotenv').config(); // Load environment variables
const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const sharedRoutes = require('./routes/sharedRoutes');
const orderRoutes = require('./routes/orderRoutes');
const layananRoutes = require('./routes/layananRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();


app.use(cors());
app.use(express.json());

// --- ROUTES DARI CONTROLLER ---
app.use('/admin', sharedRoutes); // Untuk stats
app.use('/orders', orderRoutes); // Untuk manajemen order
app.use('/layanan', layananRoutes); // Untuk manajemen layanan
app.use('/users', userRoutes); // Untuk manajemen user

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


// (Legacy user routes removed - now using userRoutes mounted at /users)


// --- ORDER & LAYANAN ---

// (Routes moved to orderRoutes.js and mounted at /orders)

// --- ADMIN FEATURES ---

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server BallMonDry running on port ${PORT}`);
});