import express from 'express';
import multer from 'multer';
import path from 'path';
import {
  getAllStudentWorks,
  getStudentWork,
  createStudentWork,
  updateStudentWork,
  deleteStudentWork
} from '../controllers/studentWorkController.js';

const router = express.Router();

// Configure multer for file uploads to disk storage
const upload = multer({
  storage: multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, path.join('public', 'uploads', 'student-works'));
    },
    filename: function (req, file, cb) {
      const ext = path.extname(file.originalname);
      const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
      cb(null, uniqueName);
    }
  }),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow images and videos
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image and video files are allowed'), false);
    }
  }
});

// Public routes (no authentication required)
router.get('/', getAllStudentWorks);
router.get('/:id', getStudentWork);

// Admin routes (authentication required)
router.post('/', upload.single('media'), createStudentWork);
router.put('/:id', upload.single('media'), updateStudentWork);
router.delete('/:id', deleteStudentWork);

export default router; 