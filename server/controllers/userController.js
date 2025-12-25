const db = require('../config/database');

// GET ALL USERS (CLIENT)
const getAllUsers = (req, res) => {
    db.query("SELECT id, username, alamat, no_hp FROM users WHERE role = 'client'", (err, result) => {
        if (err) {
            console.error('Get users error:', err);
            return res.status(500).json({ 
                message: 'Gagal mengambil data user' 
            });
        }
        res.json(result);
    });
};

// GET SINGLE USER
const getUserById = (req, res) => {
    const { id } = req.params;
    
    db.query("SELECT id, username, password, alamat, no_hp, role FROM users WHERE id = ?", [id], (err, result) => {
        if (err) {
            console.error('Get user error:', err);
            return res.status(500).json({ 
                message: 'Gagal mengambil data user' 
            });
        }
        if (result.length === 0) {
            return res.status(404).json({ 
                message: 'User tidak ditemukan' 
            });
        }
        res.json(result[0]);
    });
};

// UPDATE USER
const updateUser = (req, res) => {
    const { id, username, password, alamat, no_hp } = req.body;

    if (!id) {
        return res.status(400).json({ 
            message: "ID User tidak ditemukan" 
        });
    }

    const sql = "UPDATE users SET username = ?, password = ?, alamat = ?, no_hp = ? WHERE id = ?";
    db.query(sql, [username, password, alamat, no_hp, id], (err, result) => {
        if (err) {
            console.error('Update user error:', err);
            return res.status(500).json({ 
                message: "Gagal memperbarui profil", 
                error: err 
            });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ 
                message: "User tidak ditemukan" 
            });
        }
        
        res.json({ 
            message: "Profil berhasil diperbarui" 
        });
    });
};

module.exports = {
    getAllUsers,
    getUserById,
    updateUser
};
