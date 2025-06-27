import mongoose from 'mongoose';

const studentWorkSchema = new mongoose.Schema({
  studentName: {
    type: String,
    required: true,
    trim: true
  },
  courseName: {
    type: String,
    required: true,
    trim: true
  },
  portfolioLink: {
    type: String,
    trim: true,
    default: null
  },
  jobPosition: {
    type: String,
    trim: true,
    default: null
  },
  mediaType: {
    type: String,
    enum: ['image', 'video'],
    required: true
  },
  mediaUrl: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Method to get formatted portfolio links
studentWorkSchema.methods.getFormattedPortfolioLinks = function() {
  const links = [];
  
  if (this.portfolioLink) {
    // Simple portfolio link
    links.push({
      platform: 'Portfolio',
      url: this.portfolioLink,
      icon: 'fas fa-link'
    });
  }
  
  return links;
};

const StudentWork = mongoose.model('StudentWork', studentWorkSchema);

export default StudentWork; 