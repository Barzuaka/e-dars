import express from 'express';
import { addToCart, getCartItems, processPurchase, contactSales } from '../controllers/cartController.js';

const router = express.Router();

// Add course to cart
router.post('/add', addToCart);

// Get cart items
router.get('/items', getCartItems);

// Process purchase
router.post('/purchase', processPurchase);

// Contact sales
router.post('/contact-sales', contactSales);

export default router; 