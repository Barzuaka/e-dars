import express, { response } from "express";
import {
  createCourseForm,
  displayCourseDetails,
  displayCourses,
  handleCreateCourseForm,
  renderAdminPage,
  updateCourse,
  uploadGalleryFile,
  toggleFeatured,
  uploadLessonVideo,
  uploadCourseResource,
} from "../controllers/courseController.js";
import upload from "../config/multerConfig.js";
import multer from 'multer';
import { listUsers, getUser, updateUser, deleteUser, dashboard, learningDashboard, getUserEnrollments, addCourseToUser, removeCourseFromUser } from '../controllers/authController.js';
import Course from "../models/Course.js";
import StudentWork from "../models/StudentWork.js";
import Testimonial from "../models/Testimonial.js";
import User from "../models/User.js";
import path from 'path';

const router = express.Router();

// Middleware to check if user is authenticated
const isAuthenticated = (req, res, next) => {
  if (req.session.user) {
    next();
  } else {
    res.redirect("/login");
  }
};

// Middleware to check if user is admin
const isAdmin = (req, res, next) => {
  if (req.session.user && req.session.user.role === 'admin') {
    next();
  } else {
    res.status(403).send('Access denied');
  }
};

// @desc    Display Homepage
// @route   GET /
// @access  Public

// Display routes on the homepage
router.get("/", displayCourses); // Route now points directly to the controller function

// @desc    Display Login page
// @route   GET /login
// @access  Public
router.get("/login", (req, res) => {
  res.render("login", { path: "/login", error: null });
});

// @desc    Display Register page
// @route   GET /register
// @access  Public
router.get("/register", (req, res) => {
  res.render("register", { path: "/register", error: null });
});

// Display admin page
router.get("/admin-page", isAuthenticated, isAdmin, renderAdminPage);
// Display create course form page
router.get("/admin-page/courses/new", isAuthenticated, isAdmin, createCourseForm);

// Handle course creation using form
router.post(
  "/admin-page/courses/new",
  isAuthenticated,
  isAdmin,
  upload.fields([
    { name: 'courseThumbnail', maxCount: 1 },
    { name: 'galleryFiles', maxCount: 20 },
    { name: 'resourceFiles', maxCount: 20 }
  ]),
  handleCreateCourseForm
);

// Display one course details
router.get('/courses/:id', displayCourseDetails);

// Update course (AJAX from admin modal)
router.post("/admin-page/courses/:id/edit", isAuthenticated, isAdmin, updateCourse);

// Gallery upload for admin edit modal
router.post("/admin-page/gallery/upload", isAuthenticated, isAdmin, uploadGalleryFile);

// Toggle featured status for a course
router.post("/admin-page/courses/:id/toggle-featured", isAuthenticated, isAdmin, toggleFeatured);

// Add this route for lesson video upload
const lessonVideoUpload = multer({ 
  storage: multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, 'temp-uploads');
    },
    filename: function (req, file, cb) {
      const ext = path.extname(file.originalname);
      const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
      cb(null, uniqueName);
    }
  })
});
router.post("/admin-page/lessons/upload-video", lessonVideoUpload.single('video'), uploadLessonVideo);

// Add this route for course resource upload
const resourceUpload = multer({ 
  storage: multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, 'public/uploads/resources');
    },
    filename: function (req, file, cb) {
      const ext = path.extname(file.originalname);
      const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
      cb(null, uniqueName);
    }
  }),
  limits: {
    fileSize: 1024 * 1024 * 1024, // 1GB limit
  }
});
router.post("/admin-page/courses/upload-resource", resourceUpload.single('resource'), uploadCourseResource);

// Admin user management routes
router.get('/admin-page/users', isAuthenticated, isAdmin, listUsers);

// Admin user enrollment management routes (must come before general user routes)
router.get('/admin-page/users/:id/enrollments', isAuthenticated, isAdmin, getUserEnrollments);
router.post('/admin-page/users/enrollments/add', isAuthenticated, isAdmin, addCourseToUser);
router.post('/admin-page/users/enrollments/remove', isAuthenticated, isAdmin, removeCourseFromUser);

// General user management routes (must come after specific routes)
router.get('/admin-page/users/:id', isAuthenticated, isAdmin, getUser);
router.post('/admin-page/users/:id', isAuthenticated, isAdmin, updateUser);
router.delete('/admin-page/users/:id', isAuthenticated, isAdmin, deleteUser);

// Student dashboard
router.get('/dashboard', isAuthenticated, dashboard);

// Learning dashboard
router.get('/learning-dashboard', isAuthenticated, learningDashboard);

// Home page
const homePage = async (req, res) => {
  try {
    const courses = await Course.find();
    
    // Group courses by category
    const coursesByCategory = {};
    const categoryArray = [];
    
    courses.forEach(course => {
      if (!coursesByCategory[course.category]) {
        coursesByCategory[course.category] = [];
        categoryArray.push(course.category);
      }
      coursesByCategory[course.category].push(course);
    });
    
    // Get a random testimonial
    const testimonialCount = await Testimonial.countDocuments({ isPublished: true });
    let randomTestimonial = null;
    
    if (testimonialCount > 0) {
      const random = Math.floor(Math.random() * testimonialCount);
      randomTestimonial = await Testimonial.findOne({ isPublished: true }).skip(random);
    }
    
    res.render("index", { 
      courses, 
      coursesByCategory, 
      categoryArray,
      randomTestimonial,
      user: req.session.user || null 
    });
  } catch (error) {
    console.error("Error loading home page:", error);
    res.status(500).send("Error loading home page");
  }
};

// Student Work Gallery page
const studentWorksPage = async (req, res) => {
  try {
    const { page = 1 } = req.query;
    
    // Get student works with pagination
    const limit = 12;
    const skip = (page - 1) * limit;
    
    const studentWorks = await StudentWork.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    
    // Get total count for pagination
    const total = await StudentWork.countDocuments();
    
    res.render("student-works", {
      studentWorks,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalItems: total,
        hasNext: skip + studentWorks.length < total,
        hasPrev: page > 1
      },
      user: req.session.user || null
    });
  } catch (error) {
    console.error("Error loading student works page:", error);
    res.status(500).send("Error loading student works page");
  }
};

// Single Student Work page
const studentWorkDetailPage = async (req, res) => {
  try {
    const { id } = req.params;
    
    const studentWork = await StudentWork.findById(id);
    
    if (!studentWork) {
      return res.status(404).render("error", { 
        message: "Student work not found",
        user: req.session.user || null 
      });
    }
    
    // Check if user is admin or if work is published
    if (!studentWork.isPublished && (!req.session.user || req.session.user.role !== 'admin')) {
      return res.status(404).render("error", { 
        message: "Student work not found",
        user: req.session.user || null 
      });
    }
    
    res.render("student-work-detail", {
      studentWork,
      user: req.session.user || null
    });
  } catch (error) {
    console.error("Error loading student work detail:", error);
    res.status(500).send("Error loading student work detail");
  }
};

// Admin Student Works Management page
const adminStudentWorksPage = async (req, res) => {
  try {
    // Check if user is admin
    if (!req.session.user || req.session.user.role !== 'admin') {
      return res.redirect('/');
    }
    
    const { page = 1 } = req.query;
    const limit = 20;
    const skip = (page - 1) * limit;
    
    const studentWorks = await StudentWork.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    
    const total = await StudentWork.countDocuments();
    
    res.render("admin-student-works", {
      studentWorks,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalItems: total
      },
      user: req.session.user
    });
  } catch (error) {
    console.error("Error loading admin student works page:", error);
    res.status(500).send("Error loading admin student works page");
  }
};

// Admin Testimonials Management page
const adminTestimonialsPage = async (req, res) => {
  try {
    // Check if user is admin
    if (!req.session.user || req.session.user.role !== 'admin') {
      return res.redirect('/');
    }
    
    res.render("admin-testimonials", {
      user: req.session.user
    });
  } catch (error) {
    console.error("Error loading admin testimonials page:", error);
    res.status(500).send("Error loading admin testimonials page");
  }
};

// Course details page
const courseDetails = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    if (!course) {
      return res.status(404).render("error", { 
        message: "Course not found",
        user: req.session.user || null 
      });
    }
    res.render("course-details", { 
      course, 
      title: course.title,
      user: req.session.user || null 
    });
  } catch (error) {
    console.error("Error loading course details:", error);
    res.status(500).send("Error loading course details");
  }
};

// Testimonials page
const testimonialsPage = async (req, res) => {
  try {
    const { page = 1 } = req.query;
    
    // Get testimonials with pagination
    const limit = 10;
    const skip = (page - 1) * limit;
    
    const testimonials = await Testimonial.find({ isPublished: true })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    
    // Get total count for pagination
    const total = await Testimonial.countDocuments({ isPublished: true });
    
    res.render("testimonials", {
      testimonials,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalItems: total,
        hasNext: skip + testimonials.length < total,
        hasPrev: page > 1
      },
      user: req.session.user || null
    });
  } catch (error) {
    console.error("Error loading testimonials page:", error);
    res.status(500).send("Error loading testimonials page");
  }
};

// Route handlers
router.get("/", homePage);
router.get("/student-works", studentWorksPage);
router.get("/student-works/:id", studentWorkDetailPage);
router.get("/testimonials", testimonialsPage);
router.get("/admin/student-works", isAuthenticated, isAdmin, adminStudentWorksPage);
router.get("/admin/testimonials", isAuthenticated, isAdmin, adminTestimonialsPage);
router.get("/courses/:id", courseDetails);

// Admin routes
router.get('/admin-page', isAuthenticated, isAdmin, listUsers);
router.get('/admin-page/users', isAuthenticated, isAdmin, listUsers);
router.get('/admin-page/users/:id', isAuthenticated, isAdmin, getUser);
router.post('/admin-page/users/:id', isAuthenticated, isAdmin, updateUser);
router.delete('/admin-page/users/:id', isAuthenticated, isAdmin, deleteUser);

// User enrollment management routes
router.get('/admin/users/:userId/enrollments', isAuthenticated, isAdmin, getUserEnrollments);
router.post('/admin/users/:userId/courses/:courseId', isAuthenticated, isAdmin, addCourseToUser);
router.delete('/admin/users/:userId/courses/:courseId', isAuthenticated, isAdmin, removeCourseFromUser);

// Student dashboard
router.get('/dashboard', isAuthenticated, dashboard);

// Learning dashboard
router.get('/learning-dashboard', isAuthenticated, learningDashboard);

export default router;
