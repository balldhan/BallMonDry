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
    const { user_id, layanan_id, tipe_layanan, is_pickup } = req.body;

    if (!user_id || !layanan_id) {
        return res.status(400).json({ message: 'Data tidak valid' });
    }

    const pickupVal = (is_pickup === true || is_pickup === "true" || is_pickup === 1) ? 1 : 0;
    const tipeVal = tipe_layanan || 'reguler';

    // STATUS AWAL: 'menunggu konfirmasi'
    const sql = "INSERT INTO orders (user_id, layanan_id, tipe_layanan, is_pickup, berat, total_harga, status, tgl_order, estimasi) VALUES (?, ?, ?, ?, 0, 0, 'menunggu konfirmasi', NOW(), '-')";
    
    db.query(sql, [user_id, layanan_id, tipeVal, pickupVal], (err, result) => {
        if (err) {
            console.error("ERROR DB:", err);
            return res.status(500).json({ message: 'Gagal simpan', error: err.sqlMessage });
        }
        res.json({ message: 'Order berhasil dibuat', id: result.insertId });
    });
});

// 4. ADMIN: LIHAT SEMUA ORDER
app.get('/orders', (req, res) => {
    const sql = `
        SELECT 
            orders.id, 
            orders.tgl_order,
            orders.status, 
            orders.berat, 
            orders.total_harga, 
            orders.estimasi,
            orders.tipe_layanan,
            orders.is_pickup,
            layanan.nama_layanan,
            users.username, 
            users.alamat, 
            users.no_hp -- Pastikan ini sesuai nama kolom di DB (no_hp atau no_telepon)
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

app.put('/order/edit-client', (req, res) => {
    const { order_id, layanan_id, tipe_layanan, is_pickup } = req.body;

    // Cek Status Dulu
    db.query("SELECT status FROM orders WHERE id = ?", [order_id], (err, results) => {
        if (err || results.length === 0) return res.status(404).json({message: 'Order tak ditemukan'});
        
        // HANYA BOLEH EDIT KALAU "MENUNGGU KONFIRMASI"
        if (results[0].status !== 'menunggu konfirmasi') {
            return res.status(400).json({message: 'Pesanan sudah diproses admin, tidak bisa diedit!'});
        }

        const pickupVal = (is_pickup === true || is_pickup === 1) ? 1 : 0;
        
        // Update data
        const sql = "UPDATE orders SET layanan_id = ?, tipe_layanan = ?, is_pickup = ? WHERE id = ?";
        db.query(sql, [layanan_id, tipe_layanan, pickupVal, order_id], (errUp, resUp) => {
            if (errUp) return res.status(500).json({message: 'Gagal update'});
            res.json({message: 'Pesanan berhasil diubah'});
        });
    });
});

// --- API BARU: HAPUS ORDER (CLIENT) ---
app.delete('/order/:id', (req, res) => {
    const id = req.params.id;

    db.query("SELECT status FROM orders WHERE id = ?", [id], (err, results) => {
        if (err || results.length === 0) return res.status(404).json({message: 'Order tak ditemukan'});

        // HANYA BOLEH HAPUS KALAU "MENUNGGU KONFIRMASI"
        if (results[0].status !== 'menunggu konfirmasi') {
            return res.status(400).json({message: 'Pesanan sudah diproses, tidak bisa dibatalkan!'});
        }

        db.query("DELETE FROM orders WHERE id = ?", [id], (errDel, resDel) => {
            if (errDel) return res.status(500).json({message: 'Gagal hapus'});
            res.json({message: 'Pesanan dibatalkan'});
        });
    });
});

// 6. CLIENT: LIHAT RIWAYAT SENDIRI
app.get('/history/:user_id', (req, res) => {
    const userId = req.params.user_id;
    // Kita select "orders.*" agar layanan_id, tipe, dll terbawa
    const sql = `
        SELECT orders.*, layanan.nama_layanan 
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
    const { username, password, alamat, no_telepon } = req.body; 
    
    if (!username || !password || !alamat || !no_telepon) {
        return res.status(400).json({ message: 'Semua kolom (termasuk No HP) wajib diisi!' });
    }
    const sql = "INSERT INTO users (username, password, role, alamat, no_telepon) VALUES (?, ?, 'client', ?, ?)";
    
    db.query(sql, [username, password, alamat, no_telepon], (err, result) => {
        if (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(400).json({ message: 'Username sudah dipakai!' });
            }
            return res.status(500).json({ message: 'Gagal daftar', detail: err.sqlMessage });
        }
        res.json({ status: 'success', message: 'Hore! Akun berhasil dibuat.' });
    });
});

app.put('/order/update', (req, res) => {
    const { order_id, status, berat, estimasi } = req.body;

    // 1. Validasi Input
    if (!order_id) {
        return res.status(400).json({ message: "Order ID tidak boleh kosong" });
    }

    // 2. Ambil Info Layanan & Pickup untuk hitung harga
    const sqlGetInfo = `
        SELECT orders.*, layanan.harga_reguler, layanan.harga_express 
        FROM orders 
        JOIN layanan ON orders.layanan_id = layanan.id 
        WHERE orders.id = ?
    `;

    db.query(sqlGetInfo, [order_id], (err, results) => {
        if (err || results.length === 0) {
            return res.status(500).json({ message: 'Order tidak ditemukan atau Error DB' });
        }

        const data = results[0];

        // 3. Tentukan Harga Dasar (Reguler / Express)
        let hargaPerKg = (data.tipe_layanan === 'express') ? data.harga_express : data.harga_reguler;

        // 4. Cek Biaya Jemput (Database menyimpan 1 atau 0)
        let biayaJemput = (data.is_pickup === 1) ? 7000 : 0;

        // 5. Hitung Total Akhir
        // Pastikan berat dikonversi jadi float/angka
        let beratFloat = parseFloat(berat);
        if (isNaN(beratFloat)) beratFloat = 0; // Jaga-jaga kalau input bukan angka

        let totalHarga = (beratFloat * hargaPerKg) + biayaJemput;

        // 6. Update ke Database
        const sqlUpdate = "UPDATE orders SET status = ?, berat = ?, estimasi = ?, total_harga = ? WHERE id = ?";
        
        db.query(sqlUpdate, [status, beratFloat, estimasi, totalHarga, order_id], (errUp, resUp) => {
            if (errUp) {
                console.error(errUp);
                return res.status(500).json({ message: 'Gagal update database' });
            }
            
            res.json({ 
                message: 'Order Berhasil Diupdate', 
                detail: {
                    status: status,
                    berat: beratFloat,
                    total_final: totalHarga
                }
            });
        });
    });
});

app.put('/user/update', (req, res) => {
    const { id, username, password, alamat, no_hp } = req.body;

    // Validasi sederhana
    if (!id) return res.status(400).json({ message: "ID User tidak ditemukan" });

    const sql = "UPDATE users SET username = ?, password = ?, alamat = ?, no_hp = ? WHERE id = ?";
    db.query(sql, [username, password, alamat, no_hp, id], (err, result) => {
        if (err) return res.status(500).json({ message: "Gagal memperbarui profil", error: err });
        if (result.affectedRows === 0) return res.status(404).json({ message: "User tidak ditemukan" });
        
        res.json({ message: "Profil berhasil diperbarui" });
    });
});

// --- API: GET SINGLE USER (Untuk refresh data setelah edit) ---
app.get('/user/:id', (req, res) => {
    const id = req.params.id;
    db.query("SELECT id, username, password, alamat, no_hp, role FROM users WHERE id = ?", [id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result[0]);
    });
});

// --- API ADMIN: MANAJEMEN LAYANAN (CRUD) ---

// Tambah Layanan Baru
app.post('/layanan', (req, res) => {
    const { nama_layanan, harga_reguler, harga_express } = req.body;
    const sql = "INSERT INTO layanan (nama_layanan, harga_reguler, harga_express) VALUES (?, ?, ?)";
    db.query(sql, [nama_layanan, harga_reguler, harga_express], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: "Layanan berhasil ditambah" });
    });
});

// Update Layanan
app.put('/layanan/:id', (req, res) => {
    const { nama_layanan, harga_reguler, harga_express } = req.body;
    const sql = "UPDATE layanan SET nama_layanan = ?, harga_reguler = ?, harga_express = ? WHERE id = ?";
    db.query(sql, [nama_layanan, harga_reguler, harga_express, req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: "Layanan berhasil diupdate" });
    });
});

// Hapus Layanan
app.delete('/layanan/:id', (req, res) => {
    db.query("DELETE FROM layanan WHERE id = ?", [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: "Layanan dihapus" });
    });
});


// --- API ADMIN: MANAJEMEN USER ---

// Lihat Semua User (Pelanggan)
app.get('/users', (req, res) => {
    db.query("SELECT id, username, alamat, no_hp FROM users WHERE role = 'client'", (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});


// --- API ADMIN: LAPORAN PENDAPATAN ---

app.get('/admin/stats', (req, res) => {
    const sql = `
        SELECT 
            SUM(total_harga) as total_pendapatan,
            COUNT(id) as total_order,
            (SELECT COUNT(id) FROM orders WHERE status = 'selesai') as order_selesai,
            (SELECT COUNT(id) FROM orders WHERE status != 'selesai') as order_proses
        FROM orders 
        WHERE status != 'menunggu konfirmasi'
    `;
    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result[0]);
    });
});

app.listen(3000, () => {
    console.log('Server Smart Laundry Ready di Port 3000...');
});