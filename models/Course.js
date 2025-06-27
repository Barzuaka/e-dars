import mongoose from "mongoose";


// There are multiple subschemas
// Sub-schema for lessons within a course
const lessonSchema = new mongoose.Schema({
  title: {
    type: String,
    trim: true
  },
  videoUrl: {
    type: String,
    trim: true,
    default: ''
  }
});


const lessonSectionSchema = new mongoose.Schema(
  {
    sectionTitle: {
      type: String,
      trim: true,
      default: "Unnamed Section",
    },

    lessons: [lessonSchema],
  },
  // { _id: false } // Uncomment if you dont need ids for subsections
);

// Sub-schema for gallery items
const galleryItemSchema = new mongoose.Schema(
  {
    mediaFileType: { type: String, enum: ["image", "video"], default: "image" },
    url: {
      type: String,
      trim: true,
      required: [true, "url is reqired"],
    },
    caption: {
      type: String,
      trim: true,
    },
  },
  { _id: false }
);

// Define the course schema
const courseSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "course title is required"],
      trim: true,
    },
    category: {
      type: String,
      default: 'General',
      trim: true
    },
    thumbnailImage: {
      type: String,
      trim: true,
      default: '/uploads/thumbnails/default.jpg'
    },
    description: {
      type: String,
      required: true
    },
    introVideoID: {
      type: String,
      trim: true
    },
    totalHours: {
      type: Number,
      min: [0, 'hours cant be negative']
    },
    topicsCovered: {
      type: Number,
      min: [0, 'topics cant be negative']
    },
    numOfProjects: {
      type: Number,
      min: [0, 'projects cant be negative']
    },
    sizeGb: {
      type: Number,
      min: [0, 'size cant be negative']
    },
    numberOfLessonsManual: {
      type: Number,
      min: [0, "num of lessons cant be negative"],
      default: 0,
    },
    sections: [lessonSectionSchema],
    gallery: [galleryItemSchema],
    price: {
      type: Number,
      default: 0,
      min: [0, 'price cant be negative'],
      required: true
    },
    courseContents: {
      type: String,
      default: '',
      trim: true
    },
    featured: {
      type: Boolean,
      default: false
    },
    // Comments will be linked later, possibly as a reference to a separate 'Comment' model
  },
  {
    timestamps: true, // Automatically adds createdAt and updatedAt fields
  }
);

// Virtual property to calculate the total number of lessons. Commented out for now

/* -------
courseSchema.virtual('numberOfLessons').get(function(){
    if (this.lessons && this.lessons.length > 0) {
        return this.lessons.reduce((total, section) => {
            return total + (section.lessonTitles ? section.lessonTitles.length : 0);
        }, 0);
    }
    return 0;
});

courseSchema.set('toJSON', {virtuals: true});
courseSchema.set('toObject', {virtuals: true});

------- */

const Course = mongoose.model("Course", courseSchema);

export default Course;
