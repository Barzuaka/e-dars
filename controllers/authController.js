import User from "../models/User.js";
import Course from '../models/Course.js';
import telegramService from '../services/telegramService.js';

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
export const register = async (req, res) => {
  try {
    const { firstName, lastName, email, password } = req.body;

    // Basic validation
    if (!firstName || !lastName || !email || !password) {
      return res.status(400).json({ message: "Please enter all fields" });
    }

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Create user
    const user = await User.create({
      firstName,
      lastName,
      email,
      password,
    });

    if (user) {
      // Send Telegram notification for new user registration
      const userInfo = {
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        userAgent: req.headers['user-agent']
      };
      
      await telegramService.sendNewUserNotification(userInfo);
      
      // Don't log the user in automatically, require them to log in after registering
      res.status(201).redirect("/login");
    } else {
      res.status(400).json({ message: "Invalid user data" });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Authenticate user & get token
// @route   POST /api/auth/login
// @access  Public
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Basic validation
    if (!email || !password) {
      return res.status(400).json({ message: "Please enter all fields" });
    }

    // Check for user by email and select password
    const user = await User.findOne({ email }).select("+password");

    if (!user || !(await user.correctPassword(password, user.password))) {
      // It's better to send a generic message
      return res.status(401).render("login", {
        error: "Incorrect email or password.",
        path: "/login"
      });
    }
    
    // Create session
    req.session.user = {
      id: user._id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      role: user.role,
    };

    // Redirect admin to admin page, user to home
    if (user.role === "admin") {
      res.redirect("/admin-page");
    } else {
      res.redirect("/");
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Logout user
// @route   GET /api/auth/logout
// @access  Private
export const logout = (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ message: "Could not log out." });
    }
    res.redirect("/");
  });
};

// ADMIN: List all users
export const listUsers = async (req, res) => {
  try {
    const users = await User.find({}, '-password').sort({ createdAt: -1 });
    res.render('admin-users', { users });
  } catch (error) {
    res.status(500).send('Error fetching users');
  }
};

// ADMIN: Get single user (for edit form)
export const getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id, '-password');
    if (!user) return res.status(404).send('User not found');
    res.json(user);
  } catch (error) {
    res.status(500).send('Error fetching user');
  }
};

// ADMIN: Update user (all fields except role)
export const updateUser = async (req, res) => {
  try {
    const { firstName, lastName, email, password } = req.body;
    const user = await User.findById(req.params.id).select('+password');
    if (!user) return res.status(404).send('User not found');
    user.firstName = firstName;
    user.lastName = lastName;
    user.email = email;
    if (password && password.length >= 8) {
      user.password = password; // Will be hashed by pre-save hook
    }
    await user.save();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADMIN: Delete user
export const deleteUser = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Student dashboard
export const dashboard = async (req, res) => {
  try {
    const user = await User.findById(req.session.user.id).populate('purchasedCourses');
    const allCourses = await Course.find();
    res.render('student-dashboard', {
      user,
      myCourses: user.purchasedCourses,
      allCourses
    });
  } catch (error) {
    res.status(500).send('Error loading dashboard');
  }
};

// Learning dashboard with course and lesson selection
export const learningDashboard = async (req, res) => {
  try {
    const userId = req.session.user.id;
    const user = await User.findById(userId).populate('purchasedCourses');
    const { course: courseId, section: sectionIndex, lesson: lessonIndex } = req.query;

    let selectedCourse = null;
    let currentLesson = null;
    let hasPreviousLesson = false;
    let hasNextLesson = false;
    let progressPercentage = 0;

    if (courseId) {
      selectedCourse = user.purchasedCourses.find(c => c._id.toString() === courseId);
      
      if (selectedCourse && sectionIndex !== undefined && lessonIndex !== undefined) {
        const section = selectedCourse.sections[parseInt(sectionIndex)];
        if (section && section.lessons) {
          currentLesson = section.lessons[parseInt(lessonIndex)];
          if (currentLesson) {
            currentLesson.sectionIndex = parseInt(sectionIndex);
            currentLesson.lessonIndex = parseInt(lessonIndex);
          }
        }
      }

      // Calculate progress
      if (selectedCourse && selectedCourse.sections) {
        let totalLessons = 0;
        let completedLessons = 0;
        
        selectedCourse.sections.forEach(section => {
          if (section.lessons) {
            totalLessons += section.lessons.length;
            section.lessons.forEach(lesson => {
              if (lesson.videoUrl) {
                completedLessons++;
              }
            });
          }
        });
        
        progressPercentage = totalLessons > 0 ? Math.round((completedLessons / totalLessons) * 100) : 0;
      }

      // Check navigation availability
      if (currentLesson) {
        const currentSectionIndex = parseInt(sectionIndex);
        const currentLessonIndex = parseInt(lessonIndex);
        
        // Check if previous lesson exists
        if (currentLessonIndex > 0) {
          hasPreviousLesson = true;
        } else if (currentSectionIndex > 0) {
          const prevSection = selectedCourse.sections[currentSectionIndex - 1];
          hasPreviousLesson = prevSection && prevSection.lessons && prevSection.lessons.length > 0;
        }
        
        // Check if next lesson exists
        const currentSection = selectedCourse.sections[currentSectionIndex];
        if (currentLessonIndex < currentSection.lessons.length - 1) {
          hasNextLesson = true;
        } else if (currentSectionIndex < selectedCourse.sections.length - 1) {
          const nextSection = selectedCourse.sections[currentSectionIndex + 1];
          hasNextLesson = nextSection && nextSection.lessons && nextSection.lessons.length > 0;
        }
      }
    }

    res.render('learning-dashboard', {
      user,
      myCourses: user.purchasedCourses,
      selectedCourse,
      currentLesson,
      hasPreviousLesson,
      hasNextLesson,
      progressPercentage
    });
  } catch (error) {
    console.error('Error loading learning dashboard:', error);
    res.status(500).send('Error loading learning dashboard');
  }
};

// ADMIN: Get user enrollments (for course management)
export const getUserEnrollments = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).populate('purchasedCourses');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    const allCourses = await Course.find().select('_id title category thumbnailImage');
    
    res.json({
      success: true,
      user: {
        _id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email
      },
      enrolledCourses: user.purchasedCourses,
      allCourses: allCourses
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADMIN: Add course to user enrollments
export const addCourseToUser = async (req, res) => {
  try {
    const { userId, courseId } = req.body;
    
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    const course = await Course.findById(courseId);
    if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
    
    // Check if user is already enrolled
    if (user.purchasedCourses.includes(courseId)) {
      return res.status(400).json({ success: false, message: 'User is already enrolled in this course' });
    }
    
    // Add course to user's enrollments
    user.purchasedCourses.push(courseId);
    await user.save();
    
    res.json({ success: true, message: 'Course added to user enrollments successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADMIN: Remove course from user enrollments
export const removeCourseFromUser = async (req, res) => {
  try {
    const { userId, courseId } = req.body;
    
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    // Check if user is enrolled in the course
    if (!user.purchasedCourses.includes(courseId)) {
      return res.status(400).json({ success: false, message: 'User is not enrolled in this course' });
    }
    
    // Remove course from user's enrollments
    user.purchasedCourses = user.purchasedCourses.filter(id => id.toString() !== courseId);
    await user.save();
    
    res.json({ success: true, message: 'Course removed from user enrollments successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}; 