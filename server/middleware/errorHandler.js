// Middleware untuk error handling
const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);

    // Default error response
    const status = err.status || 500;
    const message = err.message || 'Terjadi kesalahan server';

    res.status(status).json({
        status: 'error',
        message: message,
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
};

// Middleware untuk handle 404 Not Found
const notFound = (req, res, next) => {
    res.status(404).json({
        status: 'error',
        message: 'Endpoint tidak ditemukan'
    });
};

module.exports = {
    errorHandler,
    notFound
};
