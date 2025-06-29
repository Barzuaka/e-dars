import multer from "multer";
import path from "path";
import fs from "fs";

// Storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Set folder based on field name
    let folder;
    if (file.fieldname === "courseThumbnail") {
      folder = "public/uploads/thumbnails";
    } else if (file.fieldname === "resourceFiles") {
      folder = "public/uploads/resources";
    } else {
      folder = "public/uploads/gallery";
    }

    cb(null, folder);
  },
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + "-" + file.originalname;
    cb(null, uniqueName);
  },
});

// Export the configured multer instance with increased file size limits
const upload = multer({ 
  storage,
  limits: {
    fileSize: 1024 * 1024 * 1024, // 1GB limit for resource files
  }
});

export default upload;