# Upload Structure Documentation

## Overview
This document outlines where different types of files are uploaded in the course platform.

## Upload Destinations

### 🎥 Bunny.net (Video Streaming Service)
**Purpose**: High-performance video streaming for course lesson videos
**Files**: Course lesson videos only
**Location**: CDN via Bunny.net
**Benefits**: 
- Fast video streaming
- Global CDN distribution
- Optimized for video playback
- Reduced server load

**Implementation**:
- Files are temporarily stored in `temp-uploads/`
- Uploaded to Bunny.net via API
- Temporary files are cleaned up after upload
- URLs are stored as CDN links

### 📁 Public Uploads (Local Storage)
**Purpose**: Static files that don't require streaming optimization
**Location**: `public/uploads/` directory structure

#### Directory Structure:
```
public/uploads/
├── thumbnails/          # Course thumbnail images
├── gallery/            # Course gallery images and videos
├── resources/          # Course resource files (ZIP, PDF, documents, etc.)
├── student-works/      # Student work images and videos
└── temp-uploads/       # Temporary files for Bunny.net uploads
```

## File Type Classification

### 🎥 Bunny.net (Video Streaming)
- **Course Lesson Videos**: High-quality video content for course lessons
- **File Types**: MP4, WebM, MOV, AVI, etc.
- **Size**: Typically 50MB - 2GB per video
- **Usage**: Streamed during course learning

### 📁 Public Uploads (Local Storage)

#### Course Thumbnails (`/uploads/thumbnails/`)
- **Purpose**: Course preview images
- **File Types**: JPG, PNG, WebP
- **Size**: 100KB - 2MB
- **Usage**: Course cards, course details pages

#### Gallery Items (`/uploads/gallery/`)
- **Purpose**: Course showcase images and videos
- **File Types**: JPG, PNG, WebP, MP4, WebM
- **Size**: 1MB - 50MB
- **Usage**: Course gallery, promotional content

#### Course Resources (`/uploads/resources/`)
- **Purpose**: Downloadable course materials
- **File Types**: ZIP, RAR, PDF, DOC, DOCX, TXT, BLEND, FBX, OBJ, MAX, C4D, PSD, AI, SKETCH, FIG, XD, HTML, CSS, JS, PY, JAVA, CPP, C, PHP, SQL, JSON, XML, MD, RTF, ODT, ODS, ODP, XLS, XLSX, PPT, PPTX
- **Size**: 1MB - 1GB
- **Usage**: Project files, source code, assets, documents

#### Student Works (`/uploads/student-works/`)
- **Purpose**: Student portfolio showcase
- **File Types**: JPG, PNG, WebP, MP4, WebM
- **Size**: 1MB - 50MB
- **Usage**: Student gallery, portfolio showcase

## Technical Implementation

### File Size Limits
- **Course Lesson Videos**: 50MB - 2GB (Bunny.net)
- **Course Resources**: 1MB - 1GB (Local storage)
- **Student Works**: 1MB - 50MB (Local storage)
- **Gallery Items**: 1MB - 50MB (Local storage)
- **Course Thumbnails**: 100KB - 2MB (Local storage)

### Bunny.net Upload Process
1. File uploaded to `temp-uploads/` directory
2. File read into buffer
3. Uploaded to Bunny.net via API
4. Temporary file deleted
5. CDN URL stored in database

### Local Upload Process
1. File uploaded directly to appropriate `public/uploads/` subdirectory
2. File path stored in database
3. Files served statically by web server

## Environment Variables Required

### Bunny.net Configuration
```env
BUNNY_STORAGE_ZONE_NAME=your-storage-zone-name
BUNNY_STORAGE_ACCESS_KEY=your-access-key
BUNNY_PULL_ZONE_HOSTNAME=your-pull-zone-hostname
```

### Server Configuration
The server is configured to handle large file uploads:
- Express body size limit: 1GB
- Multer file size limit: 1GB for resources
- Timeout settings may need adjustment for very large files

## Benefits of This Structure

### Performance
- **Videos**: Optimized streaming via CDN
- **Static Files**: Fast local serving
- **Bandwidth**: Reduced server bandwidth usage

### Cost Efficiency
- **Bunny.net**: Pay only for video streaming
- **Local Storage**: Free for static files
- **CDN**: Global distribution for videos only

### Scalability
- **Videos**: CDN handles global traffic
- **Static Files**: Can be moved to CDN later if needed
- **Storage**: Efficient use of resources

## Maintenance

### Cleanup
- Temporary files in `temp-uploads/` are automatically cleaned up
- Old files can be manually cleaned from `public/uploads/` if needed
- Bunny.net files are managed through their dashboard

### Backup
- Local files: Backup `public/uploads/` directory
- Bunny.net files: Managed by Bunny.net service
- Database: Backup file paths and metadata

## Security Considerations

### File Validation
- All uploads validate file types
- File size limits enforced
- Malicious file scanning recommended

### Access Control
- Admin-only uploads for course content
- Public access for viewing/downloading
- Student works require admin approval

## Future Considerations

### Potential Improvements
- Image optimization for thumbnails and gallery
- Video compression before Bunny.net upload
- CDN for static files if traffic increases
- Automated cleanup of old files
- File versioning for course resources