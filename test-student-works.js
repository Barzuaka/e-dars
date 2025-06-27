import mongoose from 'mongoose';
import StudentWork from './models/StudentWork.js';

mongoose.connect('mongodb://127.0.0.1:27017/videocourses_db')
  .then(() => {
    console.log('Connected to MongoDB');
    return StudentWork.find();
  })
  .then(works => {
    console.log('Found', works.length, 'student works');
    
    if (works.length === 0) {
      console.log('No student works found in database');
      return;
    }
    
    works.forEach((work, index) => {
      console.log(`\n--- Work ${index + 1} ---`);
      console.log('ID:', work._id);
      console.log('Student Name:', work.studentName);
      console.log('Course Name:', work.courseName);
      console.log('Job Position:', work.jobPosition);
      console.log('Portfolio Link:', work.portfolioLink);
      console.log('Images:', work.mediaFiles.images.length);
      console.log('Videos:', work.mediaFiles.videos.length);
      
      if (work.mediaFiles.images.length > 0) {
        console.log('Image URLs:');
        work.mediaFiles.images.forEach((img, i) => {
          console.log(`  ${i + 1}. ${img.url}`);
        });
      }
      
      if (work.mediaFiles.videos.length > 0) {
        console.log('Video URLs:');
        work.mediaFiles.videos.forEach((vid, i) => {
          console.log(`  ${i + 1}. ${vid.url}`);
        });
      }
    });
    
    process.exit(0);
  })
  .catch(error => {
    console.error('Error:', error);
    process.exit(1);
  }); 