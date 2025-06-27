// MongoDB initialization script
// This script runs when the MongoDB container starts for the first time

// Create the course_platform database
db = db.getSiblingDB('course_platform');

// Create a user for the application
db.createUser({
  user: 'course_user',
  pwd: 'course_password',
  roles: [
    {
      role: 'readWrite',
      db: 'course_platform'
    }
  ]
});

// Create initial collections
db.createCollection('users');
db.createCollection('courses');
db.createCollection('studentworks');

// Create indexes for better performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.courses.createIndex({ "title": 1 });
db.studentworks.createIndex({ "studentId": 1 });
db.studentworks.createIndex({ "courseId": 1 });

print('MongoDB initialization completed successfully!'); 