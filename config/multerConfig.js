import multer from "multer";
import path from "path";
import fs from "fs";

// Storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Set folder based on field name
    const folder =
      file.fieldname === "courseThumbnail"
        ? "public/uploads/thumbnails"
        : "public/uploads/gallery";

    cb(null, folder);
  },
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + "-" + file.originalname;
    cb(null, uniqueName);
  },
});

// Export the configured multer instance
const upload = multer({ storage });

export default upload;