import express from 'express';
import {
  getAllTestimonials,
  getRandomTestimonial,
  createTestimonial,
  getAllTestimonialsAdmin,
  updateTestimonial,
  deleteTestimonial,
  toggleTestimonialStatus
} from '../controllers/testimonialController.js';

const router = express.Router();

// Middleware to check if user is admin
const isAdmin = (req, res, next) => {
  if (req.session.user && req.session.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Access denied. Admin only.' });
  }
};

// Public routes (read-only)
router.get('/', getAllTestimonials);
router.get('/random', getRandomTestimonial);

// Admin routes (all CRUD operations)
router.post('/', isAdmin, createTestimonial);
router.get('/admin/all', isAdmin, getAllTestimonialsAdmin);
router.put('/:id', isAdmin, updateTestimonial);
router.delete('/:id', isAdmin, deleteTestimonial);
router.patch('/:id/toggle', isAdmin, toggleTestimonialStatus);

export default router; 