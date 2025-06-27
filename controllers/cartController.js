import Course from '../models/Course.js';
import telegramService from '../services/telegramService.js';

// Add course to cart (no notification)
export const addToCart = async (req, res) => {
  try {
    const { courseId } = req.body;
    const user = req.session.user || null;

    // Get course information
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({ success: false, message: 'Course not found' });
    }

    res.json({ 
      success: true, 
      message: 'Course added to cart successfully',
      course: {
        id: course._id,
        title: course.title,
        price: course.price,
        thumbnailImage: course.thumbnailImage
      }
    });
  } catch (error) {
    console.error('Error adding course to cart:', error);
    res.status(500).json({ success: false, message: 'Error adding course to cart' });
  }
};

// Get cart items (for display purposes)
export const getCartItems = async (req, res) => {
  try {
    const { courseIds } = req.query;
    
    if (!courseIds || courseIds.length === 0) {
      return res.json({ success: true, items: [] });
    }

    const courses = await Course.find({ _id: { $in: courseIds } });
    
    const cartItems = courses.map(course => ({
      id: course._id,
      title: course.title,
      price: course.price,
      thumbnailImage: course.thumbnailImage,
      category: course.category
    }));

    res.json({ success: true, items: cartItems });
  } catch (error) {
    console.error('Error getting cart items:', error);
    res.status(500).json({ success: false, message: 'Error getting cart items' });
  }
};

// Process purchase request
export const processPurchase = async (req, res) => {
  try {
    const { courseIds, phoneNumber } = req.body;
    const user = req.session.user || null;

    if (!courseIds || courseIds.length === 0) {
      return res.status(400).json({ success: false, message: 'No courses selected' });
    }

    // Get course information
    const courses = await Course.find({ _id: { $in: courseIds } });
    
    if (courses.length === 0) {
      return res.status(404).json({ success: false, message: 'No courses found' });
    }

    // Send Telegram notification
    await telegramService.sendPurchaseNotification(courses, user, phoneNumber);

    res.json({ 
      success: true, 
      message: 'Purchase request sent successfully. We will contact you soon!',
      courses: courses.map(course => ({
        id: course._id,
        title: course.title,
        price: course.price
      }))
    });
  } catch (error) {
    console.error('Error processing purchase:', error);
    res.status(500).json({ success: false, message: 'Error processing purchase' });
  }
};

// Contact sales form submission
export const contactSales = async (req, res) => {
  try {
    const { name, phone, course, message } = req.body;
    const user = req.session.user || null;

    // Prepare contact data
    const contactData = {
      name: name || (user ? `${user.firstName} ${user.lastName}` : 'Not provided'),
      phone: phone,
      course: course,
      message: message,
      userEmail: user ? user.email : 'Guest user'
    };

    // Send Telegram notification
    await telegramService.sendContactSalesNotification(contactData);

    res.json({ 
      success: true, 
      message: 'Thank you! We will contact you within 24 hours.' 
    });
  } catch (error) {
    console.error('Error processing contact sales request:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Something went wrong. Please try again.' 
    });
  }
}; 