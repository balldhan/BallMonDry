const db = require('../config/database');

// CREATE ORDER (REQUEST PICKUP)
const createOrder = (req, res) => {
    console.log("=== ORDER MASUK ===");
    console.log("Body dari Flutter:", req.body);

    const { user_id, layanan_id, tipe_layanan, is_pickup, estimasi } = req.body;

    if (!user_id || !layanan_id || !tipe_layanan) {
        return res.status(400).json({ 
            message: "Data order tidak lengkap" 
        });
    }

    // Pastikan is_pickup dikonversi ke 1 atau 0
    const isPickupVal = (is_pickup === true || is_pickup === 'true' || is_pickup === 1) ? 1 : 0;
    const estimasiFinal = estimasi ? estimasi : "Belum ditentukan";

    // Default status 'menunggu konfirmasi'
    const sql = `INSERT INTO orders 
               (user_id, layanan_id, tipe_layanan, is_pickup, estimasi, status, total_harga, berat, tgl_order) 
               VALUES (?, ?, ?, ?, ?, 'menunggu konfirmasi', 0, 0, NOW())`;

    const values = [user_id, layanan_id, tipe_layanan, isPickupVal, estimasiFinal];

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
            orders.status_pembayaran,
            orders.metode_pembayaran,
            orders.bukti_transfer,
            layanan.nama_layanan,
            users.username, 
            users.alamat, 
            users.no_hp,
            users.latitude,
            users.longitude
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
        ORDER BY orders.id DESC
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
const getAdminStats = async (req, res) => {
    console.log('📊 GET /admin/stats dipanggil');
    
    // Promisify helper
    const query = (sql, values) => {
        return new Promise((resolve, reject) => {
            db.query(sql, values, (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
    };

    try {
        // 1. Summary Stats
        const summarySql = `
            SELECT 
                COALESCE(SUM(CASE WHEN status_pembayaran = 'Lunas' THEN total_harga ELSE 0 END), 0) as total_pendapatan,
                SUM(CASE WHEN status != 'menunggu konfirmasi' THEN 1 ELSE 0 END) as total_order,
                SUM(CASE WHEN status = 'selesai' THEN 1 ELSE 0 END) as order_selesai,
                SUM(CASE WHEN status NOT IN ('selesai', 'menunggu konfirmasi') THEN 1 ELSE 0 END) as order_proses
            FROM orders
        `;

        // 2. Revenue Trends
        // Daily (Last 7 days)
        const dailySql = `
            SELECT DATE_FORMAT(tgl_order, '%Y-%m-%d') as date, COALESCE(SUM(total_harga), 0) as total 
            FROM orders 
            WHERE tgl_order >= DATE(NOW() - INTERVAL 6 DAY) AND status_pembayaran = 'Lunas'
            GROUP BY DATE_FORMAT(tgl_order, '%Y-%m-%d')
            ORDER BY date ASC
        `;

        // Weekly (Last 4 weeks)
        const weeklySql = `
            SELECT YEARWEEK(tgl_order, 1) as week, COALESCE(SUM(total_harga), 0) as total
            FROM orders
            WHERE tgl_order >= DATE(NOW() - INTERVAL 4 WEEK) AND status_pembayaran = 'Lunas'
            GROUP BY YEARWEEK(tgl_order, 1)
            ORDER BY week ASC
        `;

        // Monthly (Last 6 months)
        const monthlySql = `
            SELECT DATE_FORMAT(tgl_order, '%Y-%m') as month, COALESCE(SUM(total_harga), 0) as total
            FROM orders
            WHERE tgl_order >= DATE(NOW() - INTERVAL 5 MONTH) AND status_pembayaran = 'Lunas'
            GROUP BY DATE_FORMAT(tgl_order, '%Y-%m')
            ORDER BY month ASC
        `;

        // 3. Status Breakdown
        const statusSql = `SELECT status, COUNT(*) as count FROM orders GROUP BY status`;

        // 4. Service Breakdown
        const serviceSql = `
            SELECT l.nama_layanan, COUNT(*) as count 
            FROM orders o 
            JOIN layanan l ON o.layanan_id = l.id 
            GROUP BY l.nama_layanan 
            ORDER BY count DESC 
            LIMIT 5
        `;

        // 5. Type Breakdown (Regular/Express)
        const typeSql = `SELECT tipe_layanan, COUNT(*) as count FROM orders GROUP BY tipe_layanan`;

        // 6. Pickup Breakdown
        const pickupSql = `SELECT is_pickup, COUNT(*) as count FROM orders GROUP BY is_pickup`;

        // 7. Payment Breakdown (BARU)
        const paymentSql = `SELECT metode_pembayaran, COUNT(*) as count FROM orders GROUP BY metode_pembayaran`;

        const [
            summary, 
            dailyRevenue, 
            weeklyRevenue,
            monthlyRevenue, 
            statusStats, 
            serviceStats, 
            typeStats, 
            pickupStats,
            paymentStats
        ] = await Promise.all([
            query(summarySql),
            query(dailySql),
            query(weeklySql),
            query(monthlySql),
            query(statusSql),
            query(serviceSql),
            query(typeSql),
            query(pickupSql),
            query(paymentSql)
        ]);

        const stats = {
            ...summary[0],
            revenue_chart: {
                daily: dailyRevenue,
                weekly: weeklyRevenue,
                monthly: monthlyRevenue
            },
            status_breakdown: statusStats,
            service_breakdown: serviceStats,
            type_breakdown: typeStats,
            pickup_breakdown: pickupStats,
            payment_breakdown: paymentStats
        };
        
        console.log('✅ Stats result:', stats);
        res.json(stats);
    } catch (err) {
        console.error('❌ Get stats error:', err);
        return res.status(500).json({ 
            message: 'Gagal mengambil statistik',
            error: err.message
        });
    }
};

// PILIH METODE PEMBAYARAN
const pilihMetodePembayaran = (req, res) => {
    const { order_id, metode_pembayaran } = req.body;
    
    if (!order_id || !metode_pembayaran) {
        return res.status(400).json({ 
            message: 'Order ID dan metode pembayaran harus diisi' 
        });
    }
    
    // Validasi metode pembayaran
    if (!['COD', 'Transfer Bank'].includes(metode_pembayaran)) {
        return res.status(400).json({ 
            message: 'Metode pembayaran tidak valid' 
        });
    }
    
    // Update metode pembayaran
    const sql = "UPDATE orders SET metode_pembayaran = ? WHERE id = ?";
    
    db.query(sql, [metode_pembayaran, order_id], (err, result) => {
        if (err) {
            console.error('Update payment method error:', err);
            return res.status(500).json({ 
                message: 'Gagal update metode pembayaran' 
            });
        }
        
        res.json({ 
            message: 'Metode pembayaran berhasil dipilih',
            metode: metode_pembayaran
        });
    });
};

// UPLOAD BUKTI TRANSFER
const uploadBuktiTransfer = (req, res) => {
    const { order_id, bukti_transfer } = req.body;
    
    if (!order_id || !bukti_transfer) {
        return res.status(400).json({ 
            message: 'Order ID dan bukti transfer harus diisi' 
        });
    }
    
    // Simpan base64 image langsung ke database
    // Format: data:image/jpeg;base64,/9j/4AAQSkZJRg...
    const sql = `UPDATE orders 
                 SET bukti_transfer = ?, status_pembayaran = 'Menunggu Verifikasi' 
                 WHERE id = ?`;
    
    db.query(sql, [bukti_transfer, order_id], (err, result) => {
        if (err) {
            console.error('Upload bukti transfer error:', err);
            return res.status(500).json({ 
                message: 'Gagal upload bukti transfer' 
            });
        }
        
        res.json({ 
            message: 'Bukti transfer berhasil diupload',
            status_pembayaran: 'Menunggu Verifikasi'
        });
    });
};

// VERIFIKASI PEMBAYARAN (ADMIN)
const verifikasiPembayaran = (req, res) => {
    const { order_id, status_pembayaran, jumlah_dibayar } = req.body;
    
    if (!order_id || !status_pembayaran) {
        return res.status(400).json({ 
            message: 'Order ID dan status pembayaran harus diisi' 
        });
    }
    
    // Validasi status pembayaran
    if (!['Lunas', 'Belum Bayar'].includes(status_pembayaran)) {
        return res.status(400).json({ 
            message: 'Status pembayaran tidak valid' 
        });
    }
    
    // Jika status Lunas dan ada jumlah_dibayar (untuk COD), hitung kembalian
    if (status_pembayaran === 'Lunas' && jumlah_dibayar) {
        // Ambil total_harga dari order untuk hitung kembalian
        const sqlGetOrder = "SELECT total_harga FROM orders WHERE id = ?";
        
        db.query(sqlGetOrder, [order_id], (errGet, resultGet) => {
            if (errGet || resultGet.length === 0) {
                return res.status(500).json({ 
                    message: 'Gagal mengambil data order' 
                });
            }
            
            const totalHarga = resultGet[0].total_harga;
            const kembalian = parseFloat(jumlah_dibayar) - parseFloat(totalHarga);
            
            // Validasi: jumlah dibayar harus >= total harga
            if (kembalian < 0) {
                return res.status(400).json({ 
                    message: 'Jumlah dibayar tidak boleh kurang dari total harga',
                    total_harga: totalHarga,
                    jumlah_dibayar: jumlah_dibayar
                });
            }
            
            // Update dengan jumlah_dibayar dan kembalian
            const sqlUpdate = `UPDATE orders 
                              SET status_pembayaran = ?, jumlah_dibayar = ?, kembalian = ? 
                              WHERE id = ?`;
            
            db.query(sqlUpdate, [status_pembayaran, jumlah_dibayar, kembalian, order_id], (errUp, resUp) => {
                if (errUp) {
                    console.error('Verifikasi pembayaran error:', errUp);
                    return res.status(500).json({ 
                        message: 'Gagal verifikasi pembayaran' 
                    });
                }
                
                res.json({ 
                    message: 'Pembayaran berhasil diverifikasi',
                    status_pembayaran: status_pembayaran,
                    jumlah_dibayar: jumlah_dibayar,
                    kembalian: kembalian
                });
            });
        });
    } else {
        // Tanpa jumlah_dibayar (untuk Transfer Bank atau reject)
        const sql = "UPDATE orders SET status_pembayaran = ? WHERE id = ?";
        
        db.query(sql, [status_pembayaran, order_id], (err, result) => {
            if (err) {
                console.error('Verifikasi pembayaran error:', err);
                return res.status(500).json({ 
                    message: 'Gagal verifikasi pembayaran' 
                });
            }
            
            res.json({ 
                message: 'Pembayaran berhasil diverifikasi',
                status_pembayaran: status_pembayaran
            });
        });
    }
};

// GET LAYANAN LIST
const getLayanan = (req, res) => {
    db.query("SELECT * FROM layanan", (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
};

module.exports = {
    createOrder,
    getAllOrders,
    getOrderHistory,
    updateOrderByClient,
    deleteOrder,
    updateOrderByAdmin,
    getAdminStats,
    pilihMetodePembayaran,
    uploadBuktiTransfer,
    verifikasiPembayaran,
    getLayanan
};
