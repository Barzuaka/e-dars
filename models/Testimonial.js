import mongoose from 'mongoose';

const testimonialSchema = new mongoose.Schema({
  studentName: {
    type: String,
    required: [true, 'Student name is required'],
    trim: true,
    maxlength: [100, 'Student name cannot exceed 100 characters']
  },
  portfolioLink: {
    type: String,
    trim: true,
    maxlength: [500, 'Portfolio link cannot exceed 500 characters']
  },
  text: {
    type: String,
    required: [true, 'Testimonial text is required'],
    trim: true,
    maxlength: [1000, 'Testimonial text cannot exceed 1000 characters']
  },
  isPublished: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Index for efficient queries
testimonialSchema.index({ isPublished: 1, createdAt: -1 });

const Testimonial = mongoose.model('Testimonial', testimonialSchema);

export default Testimonial; 