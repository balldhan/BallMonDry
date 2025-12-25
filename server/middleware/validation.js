// Middleware untuk validasi input
const validateInput = (fields) => {
    return (req, res, next) => {
        const missingFields = [];
        
        fields.forEach(field => {
            if (!req.body[field]) {
                missingFields.push(field);
            }
        });

        if (missingFields.length > 0) {
            return res.status(400).json({
                status: 'fail',
                message: `Field berikut harus diisi: ${missingFields.join(', ')}`
            });
        }

        next();
    };
};

module.exports = {
    validateInput
};
