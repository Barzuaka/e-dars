import { title } from "process";
import Course from "../models/Course.js";
import path from 'path';
import multer from 'multer';
import { uploadVideo } from '../services/bunnyService.js';
import User from '../models/User.js';
import Testimonial from "../models/Testimonial.js";
import upload from "../config/multerConfig.js";
import fs from 'fs';

// Multer config for gallery uploads
const galleryStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join('public', 'uploads', 'gallery'));
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
    cb(null, uniqueName);
  }
});
const uploadGallery = multer({ storage: galleryStorage });

// Multer config for resource uploads
const resourceStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join('public', 'uploads', 'resources'));
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + ext;
    cb(null, uniqueName);
  }
});
const uploadResource = multer({ storage: resourceStorage });

// CREATING A COURSE
// @desc    Create a new course
// @route   POST /api/courses
// @access  Public (for now, will be Admin later)

export const createCourse = async (req, res) => {
  try {
    // req.body will contain the data sent from Postman (or a frontend form later)
    const newCourse = await Course.create(req.body);

    res.status(201).json({
      message: "Course created successfully",
      course: newCourse,
    });
  } catch (error) {
    console.error("Error creating new course, check logs.");
  }
};

// RENDER ADMIN PAGE
export const renderAdminPage = async (req, res) => {
  try {
    const courses = await Course.find().sort({ createdAt: -1 });
    res.render("admin-page", {
      message: "You can manage everything here",
      courses: courses,
    });
  } catch (error) {
    console.error("Error rendering the admin page", error);
  }
};

// RENDER CREATE COURSE FORM PAGE
export const createCourseForm = async (req, res) => {
  try {
    // Fetch all unique categories from the Course collection to make them available on the frontend
    const uniqueCategories = await Course.distinct("category");

    res.render("create-course", {
      message: "We will create a course using this form",
      categories: uniqueCategories, // Pass the categories to the EJS template
    });
  } catch (error) {
    console.error("Error rendering course creation form", error);
  }
};

// CREATE COURSE USING FORM
export const handleCreateCourseForm = async (req, res) => {
  try {
    // console.log("\n--- RECEIVED REQ.BODY ON SERVER ---");
    // console.log(JSON.stringify(req.body, null, 2)); // Stringify for pretty printing
    // console.log("--- END OF REQ.BODY ---");

    // Check req.body
    // console.log(req.body);

    // Extract data from req.body

    const dataFromForm = {
      title: req.body.title,
      category: req.body.category,
      thumbnailImage: req.files?.courseThumbnail?.[0]
        ? `/uploads/thumbnails/${req.files.courseThumbnail[0].filename}`
        : "/uploads/thumbnails/default.jpg",
      description: req.body.description,
      introVideoID: req.body.introVideoID,
      totalHours: parseFloat(req.body.totalHours),
      topicsCovered: parseFloat(req.body.topicsCovered),
      numOfProjects: parseFloat(req.body.numOfProjects),
      sizeGb: parseFloat(req.body.sizeGb),
      numberOfLessonsManual: parseFloat(req.body.numberOfLessonsManual),
      sections: req.body.sections, // testing for now
      gallery:
        req.files?.galleryFiles?.map((file) => {
          const ext = file.mimetype.split("/")[0];
          return {
            mediaFileType: ext === "video" ? "video" : "image",
            url: `/uploads/gallery/${file.filename}`,
            caption: "",
          };
        }) || [],
      resources:
        req.files?.resourceFiles?.map((file, index) => {
          return {
            fileName: file.filename,
            originalName: file.originalname,
            fileUrl: `/uploads/resources/${file.filename}`,
            fileSize: file.size,
            fileType: file.mimetype,
            description: req.body.resourceDescriptions?.[index] || "",
          };
        }) || [],
      price: parseFloat(req.body.price),
      courseContents: req.body.courseContents,
    };

    // Create course in DB
    await Course.create(dataFromForm);

    // Redirect on success
    res.status(201).redirect("/admin-page");
    console.log("Course created successfully");
    console.log(
      "Number of sections received:",
      req.body.sections ? req.body.sections.length : "none"
    ); // to test
  } catch (error) {
    console.error("Error creating course using html form", error);
  }
};

// GETTING ALL COURSES
// @desc    Get all courses (e.g., for homepage or a public listing)
// @route   GET / (when mounted on a view router) or GET /api/courses (for API)
// @access  Public

export const displayCourses = async (req, res) => {
  try {
    const courses = await Course.find();
    
    // Get featured courses
    const featuredCourses = courses.filter(course => course.featured);
    
    // Group courses by category
    const coursesByCategory = courses.reduce((acc, course) => {
      const category = course.category;
      if (!acc[category]) {
        acc[category] = [];
      }
      acc[category].push(course);
      return acc;
    }, {});

    // Get a random testimonial
    const testimonialCount = await Testimonial.countDocuments({ isPublished: true });
    let randomTestimonial = null;
    
    if (testimonialCount > 0) {
      const random = Math.floor(Math.random() * testimonialCount);
      randomTestimonial = await Testimonial.findOne({ isPublished: true }).skip(random);
    }

    // If user is logged in, populate their purchasedCourses
    let user = null;
    if (req.session.user) {
      user = await User.findById(req.session.user.id).populate('purchasedCourses');
      // Update res.locals.user with the populated user data
      res.locals.user = user;
    }

    res.render("index", {
      coursesByCategory: coursesByCategory,
      title: "Welcome to the best video course platform!",
      categoryArray: Object.keys(coursesByCategory),
      featuredCourses: featuredCourses,
      randomTestimonial: randomTestimonial,
      user: user, // Pass user data explicitly as well
    });

    // console.log(Object.keys(coursesByCategory));

    // SEND ALL COURSES (OLD)
    // res.render("index", {
    //   title: "Home - learn with best video courses",
    //   message: "Welcome to our videocourse platform",
    //   courses: courses,
    // });

    // console.log(coursesByCategory);

    // This controller can be used by an API to send JSON:
    // res.json(courses);

    // Or, if used by a view-rendering route, we can pass data to the next step (rendering)
    // For now, let's design it to be flexible. If it's rendering a page, the route handler will call res.render.
    // So, this controller's job is primarily to fetch the data.
    // Let's assume the route handler using this will decide how to respond.
    // A common pattern is to attach it to res.locals or directly pass to res.render in the route.
    return courses; // Let's return the courses for the route handler to use.
    // Or we can modify this to directly render if it's only for one view.
  } catch (error) {
    console.error("Error fetching courses:", error);
    res.status(500).render("index", {
      title: "Error",
      message: "Oops! Something went wrong loading the courses",
      courses: [], // Empty array to prevent EJS errors if 'courses' is expected
    });
    // For an API: res.status(500).json({ message: 'Error fetching courses' });
    // For a view, we'd want to render an error page or pass an error to the view.
    // Let's use 'next(error)' to pass to a generic error handler if one is set up,
    // or the route itself can handle the try-catch for rendering.
  }
};

export const displayCourseDetails = async (req, res) => {
  try {
    const courseId = req.params.id;
    const oneCourse = await Course.findById(courseId);
    
    // If user is logged in, populate their purchasedCourses
    let user = null;
    if (req.session.user) {
      user = await User.findById(req.session.user.id).populate('purchasedCourses');
      // Update res.locals.user with the populated user data
      res.locals.user = user;
    }
    
    // If ?watch=1, restrict to enrolled users
    if (req.query.watch === '1') {
      if (!req.session.user) {
        return res.redirect('/login');
      }
      const isEnrolled = user.purchasedCourses.some(cid => cid.toString() === courseId);
      if (!isEnrolled) {
        return res.status(403).render('course-details', { title: oneCourse.title, course: oneCourse, error: 'You must enroll in this course to watch the videos.' });
      }
      // Render video/lesson view (for now, reuse course-details with a flag)
      return res.render('course-details', { title: oneCourse.title, course: oneCourse, canWatch: true, user: user });
    }
    // Normal course details
    res.render('course-details', { title: oneCourse.title, course: oneCourse, user: user });
  } catch (error) {
    console.error("Cant display course data");
  }
};

// UPDATE COURSE USING FORM (AJAX)
export const updateCourse = async (req, res) => {
  try {
    const courseId = req.params.id;
    
    console.log('Updating course:', courseId);
    console.log('Request body sections:', JSON.stringify(req.body.sections, null, 2));
    
    // Parse sections data properly to preserve video URLs
    let sections = [];
    if (req.body.sections && Array.isArray(req.body.sections)) {
      sections = req.body.sections.map(section => ({
        sectionTitle: section.sectionTitle,
        lessons: section.lessons ? section.lessons.map(lesson => ({
          title: lesson.title,
          videoUrl: lesson.videoUrl || '' // Preserve video URL
        })) : []
      }));
    }
    
    console.log('Parsed sections:', JSON.stringify(sections, null, 2));
    
    // Parse gallery data properly
    let gallery = [];
    if (req.body.gallery && Array.isArray(req.body.gallery)) {
      gallery = req.body.gallery.map(item => ({
        url: item.url,
        mediaFileType: item.mediaFileType,
        caption: item.caption || ''
      }));
    }
    
    const updateData = {
      title: req.body.title,
      category: req.body.category,
      price: parseFloat(req.body.price),
      description: req.body.description,
      courseContents: req.body.courseContents,
      introVideoID: req.body.introVideoID,
      totalHours: parseFloat(req.body.totalHours),
      topicsCovered: parseFloat(req.body.topicsCovered),
      numOfProjects: parseFloat(req.body.numOfProjects),
      sizeGb: parseFloat(req.body.sizeGb),
      numberOfLessonsManual: parseFloat(req.body.numberOfLessonsManual),
      sections: sections,
      gallery: gallery,
    };
    
    console.log('Final update data sections:', JSON.stringify(updateData.sections, null, 2));
    
    const updated = await Course.findByIdAndUpdate(courseId, updateData, { new: true });
    console.log('Course updated successfully');
    res.status(200).json({ success: true, course: updated });
  } catch (error) {
    console.error('Error updating course:', error);
    res.status(500).json({ success: false, error: 'Failed to update course' });
  }
};

export const uploadGalleryFile = [
  uploadGallery.single('galleryFile'),
  (req, res) => {
    if (!req.file) {
      return res.json({ success: false, error: 'No file uploaded' });
    }
    const url = `/uploads/gallery/${req.file.filename}`;
    const mime = req.file.mimetype;
    const mediaFileType = mime.startsWith('video') ? 'video' : 'image';
    res.json({ success: true, url, mediaFileType });
  }
];

// Toggle featured status for a course
export const toggleFeatured = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    if (!course) return res.status(404).json({ success: false, error: 'Course not found' });
    course.featured = !course.featured;
    await course.save();
    res.json({ success: true, featured: course.featured });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to toggle featured' });
  }
};

// UPLOAD LESSON VIDEO
export const uploadLessonVideo = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No video file uploaded' });
    }

    // Read the file from disk and upload to Bunny.net
    const fileBuffer = fs.readFileSync(req.file.path);
    const videoUrl = await uploadVideo(fileBuffer, req.file.filename, 'lesson-videos');

    // Clean up the temporary file
    fs.unlinkSync(req.file.path);

    res.json({ 
      success: true, 
      url: videoUrl,
      message: 'Video uploaded successfully' 
    });
  } catch (error) {
    console.error('Error uploading lesson video:', error);
    res.status(500).json({ success: false, message: 'Error uploading video' });
  }
};

// UPLOAD COURSE RESOURCE
export const uploadCourseResource = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No resource file uploaded' });
    }

    const fileUrl = `/uploads/resources/${req.file.filename}`;

    res.json({ 
      success: true, 
      url: fileUrl,
      fileName: req.file.filename,
      message: 'Resource uploaded successfully' 
    });
  } catch (error) {
    console.error('Error uploading course resource:', error);
    res.status(500).json({ success: false, message: 'Error uploading resource' });
  }
};

// Student enrolls in a course
export const enrollInCourse = async (req, res) => {
  try {
    const userId = req.session.user.id;
    const courseId = req.params.id;
    const user = await User.findById(userId);
    if (!user.purchasedCourses.includes(courseId)) {
      user.purchasedCourses.push(courseId);
      await user.save();
    }
    res.redirect('/dashboard');
  } catch (error) {
    res.status(500).send('Error enrolling in course');
  }
};
