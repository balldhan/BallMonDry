const db = require('../config/database');

// CREATE ORDER (REQUEST PICKUP)
const createOrder = (req, res) => {
    console.log("=== ORDER MASUK ===");
    console.log("Body dari Flutter:", req.body);
    console.log("Nilai Estimasi:", req.body.estimasi);

    const { user_id, layanan_id, tipe_layanan, is_pickup, estimasi } = req.body;

    if (!user_id || !layanan_id || !tipe_layanan) {
        return res.status(400).json({ 
            message: "Data order tidak lengkap" 
        });
    }

    const estimasiFinal = estimasi ? estimasi : "Belum ditentukan";

    const sql = `INSERT INTO orders 
               (user_id, layanan_id, tipe_layanan, is_pickup, estimasi, status, total_harga, berat, tgl_order) 
               VALUES (?, ?, ?, ?, ?, 'menunggu konfirmasi', 0, 0, NOW())`;

    const values = [user_id, layanan_id, tipe_layanan, is_pickup, estimasiFinal];

    db.query(sql, values, (err, result) => {
        if (err) {
            console.error("Error Database:", err);
            return res.status(500).json({ 
                message: "Gagal membuat order" 
            });
        }
        console.log("Sukses Insert ID:", result.insertId);
        return res.status(200).json({ 
            message: "Order berhasil dibuat", 
            id: result.insertId 
        });
    });
};

// GET ALL ORDERS (ADMIN)
const getAllOrders = (req, res) => {
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
            users.no_hp
        FROM orders
        JOIN users ON orders.user_id = users.id
        JOIN layanan ON orders.layanan_id = layanan.id
        ORDER BY orders.id DESC
    `;
    
    db.query(sql, (err, result) => {
        if (err) {
            console.error('Get orders error:', err);
            return res.status(500).json({ 
                message: 'Gagal mengambil data order' 
            });
        }
        res.json(result);
    });
};

// GET ORDER HISTORY BY USER
const getOrderHistory = (req, res) => {
    const { user_id } = req.params;
    
    const sql = `
        SELECT orders.*, layanan.nama_layanan 
        FROM orders
        JOIN layanan ON orders.layanan_id = layanan.id
        WHERE orders.user_id = ?
        ORDER BY orders.tgl_order DESC
    `;
    
    db.query(sql, [user_id], (err, result) => {
        if (err) {
            console.error('Get history error:', err);
            return res.status(500).json({ 
                message: 'Gagal mengambil riwayat order' 
            });
        }
        res.json(result);
    });
};

// UPDATE ORDER (CLIENT EDIT)
const updateOrderByClient = (req, res) => {
    const { order_id, layanan_id, tipe_layanan, is_pickup, estimasi } = req.body;

    if (!order_id) {
        return res.status(400).json({ 
            message: 'Order ID harus diisi' 
        });
    }

    // Cek Status Dulu
    db.query("SELECT status FROM orders WHERE id = ?", [order_id], (err, results) => {
        if (err || results.length === 0) {
            return res.status(404).json({ 
                message: 'Order tak ditemukan' 
            });
        }
        
        if (results[0].status !== 'menunggu konfirmasi') {
            return res.status(400).json({ 
                message: 'Pesanan sudah diproses admin, tidak bisa diedit!' 
            });
        }

        const pickupVal = (is_pickup === true || is_pickup === 1) ? 1 : 0;
        const sql = "UPDATE orders SET layanan_id = ?, tipe_layanan = ?, is_pickup = ?, estimasi = ? WHERE id = ?";
        
        db.query(sql, [layanan_id, tipe_layanan, pickupVal, estimasi, order_id], (errUp, resUp) => {
            if (errUp) {
                console.error('Update order error:', errUp);
                return res.status(500).json({ 
                    message: 'Gagal update' 
                });
            }
            res.json({ 
                message: 'Pesanan berhasil diubah' 
            });
        });
    });
};

// DELETE ORDER (CLIENT CANCEL)
const deleteOrder = (req, res) => {
    const { id } = req.params;

    db.query("SELECT status FROM orders WHERE id = ?", [id], (err, results) => {
        if (err || results.length === 0) {
            return res.status(404).json({ 
                message: 'Order tak ditemukan' 
            });
        }

        if (results[0].status !== 'menunggu konfirmasi') {
            return res.status(400).json({ 
                message: 'Pesanan sudah diproses, tidak bisa dibatalkan!' 
            });
        }

        db.query("DELETE FROM orders WHERE id = ?", [id], (errDel, resDel) => {
            if (errDel) {
                console.error('Delete order error:', errDel);
                return res.status(500).json({ 
                    message: 'Gagal hapus' 
                });
            }
            res.json({ 
                message: 'Pesanan dibatalkan' 
            });
        });
    });
};

// UPDATE ORDER (ADMIN)
const updateOrderByAdmin = (req, res) => {
    const { order_id, status, berat, estimasi } = req.body;

    if (!order_id) {
        return res.status(400).json({ 
            message: "Order ID tidak boleh kosong" 
        });
    }

    // Ambil Info Layanan & Pickup untuk hitung harga
    const sqlGetInfo = `
        SELECT orders.*, layanan.harga_reguler, layanan.harga_express 
        FROM orders 
        JOIN layanan ON orders.layanan_id = layanan.id 
        WHERE orders.id = ?
    `;

    db.query(sqlGetInfo, [order_id], (err, results) => {
        if (err || results.length === 0) {
            return res.status(500).json({ 
                message: 'Order tidak ditemukan atau Error DB' 
            });
        }

        const data = results[0];

        // Tentukan Harga Dasar (Reguler / Express)
        let hargaPerKg = (data.tipe_layanan === 'express') 
            ? data.harga_express 
            : data.harga_reguler;

        // Cek Biaya Jemput
        let biayaJemput = (data.is_pickup === 1) ? 7000 : 0;

        // Hitung Total Akhir
        let beratFloat = parseFloat(berat);
        if (isNaN(beratFloat)) beratFloat = 0;

        let totalHarga = (beratFloat * hargaPerKg) + biayaJemput;

        // Update ke Database
        const sqlUpdate = "UPDATE orders SET status = ?, berat = ?, estimasi = ?, total_harga = ? WHERE id = ?";
        
        db.query(sqlUpdate, [status, beratFloat, estimasi, totalHarga, order_id], (errUp, resUp) => {
            if (errUp) {
                console.error('Update order error:', errUp);
                return res.status(500).json({ 
                    message: 'Gagal update database' 
                });
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
};

// GET ADMIN STATS
const getAdminStats = (req, res) => {
    console.log('📊 GET /admin/stats dipanggil');
    
    const sql = `
        SELECT 
            COALESCE(SUM(CASE WHEN status != 'menunggu konfirmasi' THEN total_harga ELSE 0 END), 0) as total_pendapatan,
            SUM(CASE WHEN status != 'menunggu konfirmasi' THEN 1 ELSE 0 END) as total_order,
            SUM(CASE WHEN status = 'selesai' THEN 1 ELSE 0 END) as order_selesai,
            SUM(CASE WHEN status NOT IN ('selesai', 'menunggu konfirmasi') THEN 1 ELSE 0 END) as order_proses
        FROM orders
    `;
    
    db.query(sql, (err, result) => {
        if (err) {
            console.error('❌ Get stats error:', err);
            return res.status(500).json({ 
                message: 'Gagal mengambil statistik',
                error: err.message
            });
        }
        
        // Pastikan selalu return object dengan default values
        const stats = result && result[0] ? result[0] : {
            total_pendapatan: 0,
            total_order: 0,
            order_selesai: 0,
            order_proses: 0
        };
        
        console.log('✅ Stats result:', stats);
        res.json(stats);
    });
};

module.exports = {
    createOrder,
    getAllOrders,
    getOrderHistory,
    updateOrderByClient,
    deleteOrder,
    updateOrderByAdmin,
    getAdminStats
};
