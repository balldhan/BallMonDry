require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();

// Import database connection
require('./config/database');

// Import routes
const authRoutes = require('./routes/authRoutes');
const orderRoutes = require('./routes/orderRoutes');
const layananRoutes = require('./routes/layananRoutes');
const userRoutes = require('./routes/userRoutes');
const sharedRoutes = require('./routes/sharedRoutes');

// Import middleware
const { errorHandler, notFound } = require('./middleware/errorHandler');

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/', authRoutes);           
app.use('/order', orderRoutes);     
app.use('/orders', orderRoutes);    
app.use('/history', sharedRoutes);  
app.use('/admin', sharedRoutes);    
app.use('/layanan', layananRoutes); 
app.use('/user', userRoutes);       
app.use('/users', userRoutes);      

// 404 Handler
app.use(notFound);

// Error Handler
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server Smart Laundry Ready di Port ${PORT}...`);
});