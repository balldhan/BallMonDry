const db = require('../config/database');

// LOGIN
const login = (req, res) => {
    const { username, password } = req.body;
    
    if (!username || !password) {
        return res.status(400).json({ 
            status: 'fail', 
            message: 'Username dan password harus diisi' 
        });
    }

    const sql = "SELECT * FROM users WHERE username = ? AND password = ?";
    db.query(sql, [username, password], (err, result) => {
        if (err) {
            console.error('Login error:', err);
            return res.status(500).json({ 
                status: 'fail', 
                message: 'Terjadi kesalahan server' 
            });
        }
        
        if (result.length > 0) {
            res.json({ 
                status: 'success', 
                data: result[0] 
            });
        } else {
            res.status(401).json({ 
                status: 'fail', 
                message: 'Username/Password salah' 
            });
        }
    });
};

// REGISTER
const register = (req, res) => {
    const { username, password, alamat, no_telepon } = req.body;
    
    if (!username || !password || !alamat || !no_telepon) {
        return res.status(400).json({ 
            message: 'Semua kolom (termasuk No HP) wajib diisi!' 
        });
    }

    const sql = "INSERT INTO users (username, password, role, alamat, no_hp) VALUES (?, ?, 'client', ?, ?)";
    
    db.query(sql, [username, password, alamat, no_telepon], (err, result) => {
        if (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(400).json({ 
                    message: 'Username sudah dipakai!' 
                });
            }
            console.error('Register error:', err);
            return res.status(500).json({ 
                message: 'Gagal daftar', 
                detail: err.sqlMessage 
            });
        }
        
        res.json({ 
            status: 'success', 
            message: 'Hore! Akun berhasil dibuat.' 
        });
    });
};

module.exports = {
    login,
    register
};
