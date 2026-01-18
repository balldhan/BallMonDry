const db = require('../config/database');

// GET ALL LAYANAN
const getAllLayanan = (req, res) => {
    console.log("GET /layanan received");
    const sql = "SELECT * FROM layanan";
    db.query(sql, (err, result) => {
        if (err) {
            console.error('Get layanan error:', err);
            return res.status(500).json({ 
                message: 'Gagal mengambil data layanan' 
            });
        }
        res.json(result);
    });
};

// CREATE LAYANAN
const createLayanan = (req, res) => {
    const { nama_layanan, harga_reguler, harga_express, jam_reguler, jam_express } = req.body;
    
    if (!nama_layanan || !harga_reguler || !harga_express || !jam_reguler || !jam_express) {
        return res.status(400).json({ 
            message: 'Semua field harus diisi' 
        });
    }

    const sql = "INSERT INTO layanan (nama_layanan, harga_reguler, harga_express, jam_reguler, jam_express) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [nama_layanan, harga_reguler, harga_express, jam_reguler, jam_express], (err, result) => {
        if (err) {
            console.error('Create layanan error:', err);
            return res.status(500).json({ 
                message: 'Gagal menambah layanan' 
            });
        }
        res.json({ 
            message: "Layanan berhasil ditambah",
            id: result.insertId
        });
    });
};

// UPDATE LAYANAN
const updateLayanan = (req, res) => {
    const { id } = req.params;
    const { nama_layanan, harga_reguler, harga_express, jam_reguler, jam_express } = req.body;
    
    if (!nama_layanan || !harga_reguler || !harga_express || !jam_reguler || !jam_express) {
        return res.status(400).json({ 
            message: 'Semua field harus diisi' 
        });
    }

    const sql = "UPDATE layanan SET nama_layanan = ?, harga_reguler = ?, harga_express = ?, jam_reguler = ?, jam_express = ? WHERE id = ?";
    db.query(sql, [nama_layanan, harga_reguler, harga_express, jam_reguler, jam_express, id], (err, result) => {
        if (err) {
            console.error('Update layanan error:', err);
            return res.status(500).json({ 
                message: 'Gagal update layanan' 
            });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ 
                message: 'Layanan tidak ditemukan' 
            });
        }
        res.json({ 
            message: "Layanan berhasil diupdate" 
        });
    });
};

// DELETE LAYANAN
const deleteLayanan = (req, res) => {
    const { id } = req.params;
    
    db.query("DELETE FROM layanan WHERE id = ?", [id], (err, result) => {
        if (err) {
            console.error('Delete layanan error:', err);
            return res.status(500).json({ 
                message: 'Gagal menghapus layanan' 
            });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ 
                message: 'Layanan tidak ditemukan' 
            });
        }
        res.json({ 
            message: "Layanan berhasil dihapus" 
        });
    });
};

module.exports = {
    getAllLayanan,
    createLayanan,
    updateLayanan,
    deleteLayanan
};
