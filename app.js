import express from "express";
import dotenv from "dotenv";
import path from "path";
import session from "express-session";
import MongoStore from "connect-mongo";
import { PROJECT_ROOT } from "./config/paths.js";
import connectDB from "./config/db.js";
import courseRoutes from './routes/courseRoutes.js';
import viewRoutes from './routes/viewRoutes.js'
import authRoutes from "./routes/authRoutes.js";
import cartRoutes from "./routes/cartRoutes.js";
import studentWorkRoutes from "./routes/studentWorkRoutes.js";
import testimonialRoutes from "./routes/testimonialRoutes.js";
import User from "./models/User.js"; // Import the User model

dotenv.config();
connectDB();

const app = express();
const PORT = process.env.PORT || 3001;

// Create a default admin user if one doesn't exist
const createAdminUser = async () => {
  try {
    const adminExists = await User.findOne({ email: process.env.ADMIN_EMAIL });
    if (!adminExists) {
      await User.create({
        firstName: "Admin",
        lastName: "User",
        email: process.env.ADMIN_EMAIL,
        password: process.env.ADMIN_PASSWORD,
        role: "admin",
      });
      console.log("Admin user created successfully.");
    }
  } catch (error) {
    console.error("Error creating admin user:", error);
  }
};
createAdminUser();

// Session Middleware
app.use(
  session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    store: MongoStore.create({
      mongoUrl: process.env.MONGO_URI,
      collectionName: "sessions",
    }),
    cookie: {
      maxAge: 1000 * 60 * 60 * 24, // 1 day
    },
  })
);

// Middleware to make user available in all views
app.use(async (req, res, next) => {
  if (req.session.user) {
    try {
      // Populate user with purchased courses
      const populatedUser = await User.findById(req.session.user.id).populate('purchasedCourses');
      res.locals.user = populatedUser;
    } catch (error) {
      console.error('Error populating user data:', error);
      res.locals.user = req.session.user;
    }
  } else {
    res.locals.user = null;
  }
  next();
});

// Middleware for parsing request bodies
app.use(express.json({ limit: '1gb' })); // for parsing json data, e.g. postman sends json data but html forms send url encoded data
app.use(express.urlencoded({extended: true, limit: '1gb'})); // For parsing application/x-www-form-urlencoded

// View Engine Setup
app.set("view engine", "ejs");
// Use PROJECT_ROOT to construct paths
app.set("views", path.join(PROJECT_ROOT, "views")); // Tell Express where your views are

// Cofiguring the path to serve static files
app.use(express.static(path.join(PROJECT_ROOT, 'public')));

// Auth routes
app.use("/api/auth", authRoutes);

// Course routes
app.use('/api/courses', courseRoutes);

// Cart routes
app.use('/api/cart', cartRoutes);

// Student Work routes
app.use('/api/student-works', studentWorkRoutes);

// Testimonial routes
app.use('/api/testimonials', testimonialRoutes);

// Health check endpoint for monitoring
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// A simple route to test rendering an EJS view
app.use("/", viewRoutes);

app.listen(PORT, () => {
  console.log(`Me listening on port ${PORT}`);
});
