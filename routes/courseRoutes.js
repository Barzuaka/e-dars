import express from 'express';
import { createCourse } from '../controllers/courseController.js';


const router = express.Router();

// Route for creating a new course
// POST /api/courses
router.post('/', createCourse);

export default router;