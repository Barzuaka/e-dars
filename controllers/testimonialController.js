import Testimonial from '../models/Testimonial.js';

// @desc    Get all published testimonials
// @route   GET /api/testimonials
// @access  Public
export const getAllTestimonials = async (req, res) => {
  try {
    const testimonials = await Testimonial.find({ isPublished: true })
      .sort({ createdAt: -1 });
    
    res.json(testimonials);
  } catch (error) {
    console.error('Error fetching testimonials:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get a random testimonial
// @route   GET /api/testimonials/random
// @access  Public
export const getRandomTestimonial = async (req, res) => {
  try {
    const count = await Testimonial.countDocuments({ isPublished: true });
    
    if (count === 0) {
      return res.json(null);
    }
    
    const random = Math.floor(Math.random() * count);
    const testimonial = await Testimonial.findOne({ isPublished: true })
      .skip(random);
    
    res.json(testimonial);
  } catch (error) {
    console.error('Error fetching random testimonial:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Create a new testimonial (admin only)
// @route   POST /api/testimonials
// @access  Private (Admin)
export const createTestimonial = async (req, res) => {
  try {
    const { studentName, text } = req.body;
    
    if (!studentName || !text) {
      return res.status(400).json({ 
        message: 'Student name and testimonial text are required' 
      });
    }
    
    const testimonial = new Testimonial({
      studentName,
      text
    });
    
    await testimonial.save();
    
    res.status(201).json({
      message: 'Testimonial created successfully',
      testimonial
    });
  } catch (error) {
    console.error('Error creating testimonial:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get all testimonials (admin only)
// @route   GET /api/testimonials/admin/all
// @access  Private (Admin)
export const getAllTestimonialsAdmin = async (req, res) => {
  try {
    const testimonials = await Testimonial.find()
      .sort({ createdAt: -1 });
    
    res.json(testimonials);
  } catch (error) {
    console.error('Error fetching testimonials:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Update testimonial (admin only)
// @route   PUT /api/testimonials/:id
// @access  Private (Admin)
export const updateTestimonial = async (req, res) => {
  try {
    const { id } = req.params;
    const { studentName, text, isPublished } = req.body;
    
    const testimonial = await Testimonial.findById(id);
    
    if (!testimonial) {
      return res.status(404).json({ message: 'Testimonial not found' });
    }
    
    testimonial.studentName = studentName || testimonial.studentName;
    testimonial.text = text || testimonial.text;
    testimonial.isPublished = isPublished !== undefined ? isPublished : testimonial.isPublished;
    
    await testimonial.save();
    
    res.json({
      message: 'Testimonial updated successfully',
      testimonial
    });
  } catch (error) {
    console.error('Error updating testimonial:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Delete testimonial (admin only)
// @route   DELETE /api/testimonials/:id
// @access  Private (Admin)
export const deleteTestimonial = async (req, res) => {
  try {
    const { id } = req.params;
    
    const testimonial = await Testimonial.findByIdAndDelete(id);
    
    if (!testimonial) {
      return res.status(404).json({ message: 'Testimonial not found' });
    }
    
    res.json({ message: 'Testimonial deleted successfully' });
  } catch (error) {
    console.error('Error deleting testimonial:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Toggle testimonial published status (admin only)
// @route   PATCH /api/testimonials/:id/toggle
// @access  Private (Admin)
export const toggleTestimonialStatus = async (req, res) => {
  try {
    const { id } = req.params;
    
    const testimonial = await Testimonial.findById(id);
    
    if (!testimonial) {
      return res.status(404).json({ message: 'Testimonial not found' });
    }
    
    testimonial.isPublished = !testimonial.isPublished;
    await testimonial.save();
    
    res.json({
      message: `Testimonial ${testimonial.isPublished ? 'published' : 'unpublished'} successfully`,
      testimonial
    });
  } catch (error) {
    console.error('Error toggling testimonial status:', error);
    res.status(500).json({ message: 'Server error' });
  }
}; 