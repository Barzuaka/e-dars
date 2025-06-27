import mongoose from "mongoose";
import User from "./models/User.js";
import dotenv from "dotenv";

dotenv.config();

// Connect to MongoDB
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/course-platform');
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    process.exit(1);
  }
};

const createAdminUser = async () => {
  try {
    await connectDB();
    
    // Check if admin already exists
    const existingAdmin = await User.findOne({ role: 'admin' });
    
    if (existingAdmin) {
      console.log('Admin user already exists:');
      console.log(`Email: ${existingAdmin.email}`);
      console.log(`Name: ${existingAdmin.firstName} ${existingAdmin.lastName}`);
      console.log(`Role: ${existingAdmin.role}`);
      
      // Ask if user wants to reset password
      console.log('\nTo reset admin password, run: node create-admin.js reset');
      return;
    }
    
    // Create new admin user
    const adminUser = await User.create({
      firstName: "Admin",
      lastName: "User", 
      email: "admin@edars.com",
      password: "admin123456",
      role: "admin"
    });
    
    console.log('✅ Admin user created successfully!');
    console.log(`Email: ${adminUser.email}`);
    console.log(`Password: admin123456`);
    console.log(`Name: ${adminUser.firstName} ${adminUser.lastName}`);
    console.log(`Role: ${adminUser.role}`);
    
  } catch (error) {
    console.error('Error creating admin user:', error);
  } finally {
    mongoose.connection.close();
  }
};

const resetAdminPassword = async () => {
  try {
    await connectDB();
    
    const adminUser = await User.findOne({ role: 'admin' });
    
    if (!adminUser) {
      console.log('No admin user found. Creating new admin user...');
      await createAdminUser();
      return;
    }
    
    // Reset password
    adminUser.password = "admin123456";
    await adminUser.save();
    
    console.log('✅ Admin password reset successfully!');
    console.log(`Email: ${adminUser.email}`);
    console.log(`New Password: admin123456`);
    console.log(`Name: ${adminUser.firstName} ${adminUser.lastName}`);
    
  } catch (error) {
    console.error('Error resetting admin password:', error);
  } finally {
    mongoose.connection.close();
  }
};

// Check command line argument
const command = process.argv[2];

if (command === 'reset') {
  resetAdminPassword();
} else {
  createAdminUser();
} 