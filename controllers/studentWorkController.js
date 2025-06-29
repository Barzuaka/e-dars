import StudentWork from '../models/StudentWork.js';
import multer from 'multer';
import path from 'path';

// Multer config for student work uploads
const studentWorkStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join('public', 'uploads', 'student-works'));
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
    cb(null, uniqueName);
  }
});
const uploadStudentWork = multer({ storage: studentWorkStorage });

// @desc    Get all student works
// @route   GET /api/student-works
// @access  Public
export const getAllStudentWorks = async (req, res) => {
  try {
    const studentWorks = await StudentWork.find().sort({ createdAt: -1 });
    res.json({ success: true, data: studentWorks });
  } catch (error) {
    console.error('Error fetching student works:', error);
    res.status(500).json({ success: false, message: 'Error fetching student works' });
  }
};

// @desc    Get single student work
// @route   GET /api/student-works/:id
// @access  Public
export const getStudentWork = async (req, res) => {
  try {
    const studentWork = await StudentWork.findById(req.params.id);
    if (!studentWork) {
      return res.status(404).json({ success: false, message: 'Student work not found' });
    }
    res.json({ success: true, data: studentWork });
  } catch (error) {
    console.error('Error fetching student work:', error);
    res.status(500).json({ success: false, message: 'Error fetching student work' });
  }
};

// @desc    Create new student work
// @route   POST /api/student-works
// @access  Admin only
export const createStudentWork = async (req, res) => {
  try {
    const { studentName, courseName, portfolioLink, jobPosition } = req.body;
    if (!studentName || !courseName) {
      return res.status(400).json({ success: false, message: 'Student name and course name are required' });
    }
    // Accept a single file (image or video)
    const file = req.file;
    if (!file) {
      return res.status(400).json({ success: false, message: 'A media file is required' });
    }
    // Auto-detect media type
    let mediaType = '';
    if (file.mimetype.startsWith('image/')) {
      mediaType = 'image';
    } else if (file.mimetype.startsWith('video/')) {
      mediaType = 'video';
    } else {
      return res.status(400).json({ success: false, message: 'Only image or video files are allowed' });
    }
    // Create student work
    const studentWork = new StudentWork({
      studentName,
      courseName,
      portfolioLink: portfolioLink || null,
      jobPosition: jobPosition || null,
      mediaType,
      mediaUrl: `/uploads/student-works/${file.filename}`
    });
    await studentWork.save();
    res.status(201).json({ success: true, message: 'Student work created successfully', data: studentWork });
  } catch (error) {
    console.error('Error creating student work:', error);
    res.status(500).json({ success: false, message: 'Error creating student work' });
  }
};

// @desc    Update student work
// @route   PUT /api/student-works/:id
// @access  Admin only
export const updateStudentWork = async (req, res) => {
  try {
    const { studentName, courseName, portfolioLink, jobPosition } = req.body;
    const studentWork = await StudentWork.findById(req.params.id);
    if (!studentWork) {
      return res.status(404).json({ success: false, message: 'Student work not found' });
    }
    studentWork.studentName = studentName;
    studentWork.courseName = courseName;
    studentWork.portfolioLink = portfolioLink || null;
    studentWork.jobPosition = jobPosition || null;
    // If a new file is uploaded, replace the media
    if (req.file) {
      let mediaType = '';
      if (req.file.mimetype.startsWith('image/')) {
        mediaType = 'image';
      } else if (req.file.mimetype.startsWith('video/')) {
        mediaType = 'video';
      } else {
        return res.status(400).json({ success: false, message: 'Only image or video files are allowed' });
      }
      studentWork.mediaType = mediaType;
      studentWork.mediaUrl = `/uploads/student-works/${req.file.filename}`;
    }
    await studentWork.save();
    res.json({ success: true, message: 'Student work updated successfully', data: studentWork });
  } catch (error) {
    console.error('Error updating student work:', error);
    res.status(500).json({ success: false, message: 'Error updating student work' });
  }
};

// @desc    Delete student work
// @route   DELETE /api/student-works/:id
// @access  Admin only
export const deleteStudentWork = async (req, res) => {
  try {
    const studentWork = await StudentWork.findById(req.params.id);
    if (!studentWork) {
      return res.status(404).json({ success: false, message: 'Student work not found' });
    }
    await StudentWork.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Student work deleted successfully' });
  } catch (error) {
    console.error('Error deleting student work:', error);
    res.status(500).json({ success: false, message: 'Error deleting student work' });
  }
}; 