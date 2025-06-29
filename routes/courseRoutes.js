import express from 'express';
import { createCourse, uploadCourseResource } from '../controllers/courseController.js';
import multer from 'multer';
import path from 'path';

// Multer config for resource uploads
const resourceStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'public/uploads/resources');
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
    cb(null, uniqueName);
  }
});
const uploadResource = multer({ 
  storage: resourceStorage,
  limits: {
    fileSize: 1024 * 1024 * 1024, // 1GB limit
  }
});

const router = express.Router();

// Route for creating a new course
// POST /api/courses
router.post('/', createCourse);

// Route for uploading course resources
// POST /api/courses/upload-resource
router.post('/upload-resource', uploadResource.single('resource'), uploadCourseResource);

export default router;