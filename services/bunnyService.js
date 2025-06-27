import axios from 'axios';
import fs from 'fs';
import path from 'path';

const BUNNY_STORAGE_ZONE_NAME = process.env.BUNNY_STORAGE_ZONE_NAME;
const BUNNY_STORAGE_ACCESS_KEY = process.env.BUNNY_STORAGE_ACCESS_KEY;
const BUNNY_PULL_ZONE_HOSTNAME = process.env.BUNNY_PULL_ZONE_HOSTNAME;

/**
 * Uploads a video file to Bunny.net Storage Zone
 * @param {Buffer} fileBuffer - The file buffer
 * @param {string} fileName - The name to save the file as (e.g. lesson1.mp4)
 * @param {string} [folder] - Optional folder path inside the storage zone
 * @returns {Promise<string>} - The CDN URL of the uploaded file
 */
export async function uploadVideo(fileBuffer, fileName, folder = "") {
  const storagePath = folder ? `${folder}/${fileName}` : fileName;
  const url = `https://storage.bunnycdn.com/${BUNNY_STORAGE_ZONE_NAME}/${storagePath}`;

  // Check for missing Bunny.net environment variables
  const missingVars = [];
  if (!BUNNY_STORAGE_ZONE_NAME) missingVars.push('BUNNY_STORAGE_ZONE_NAME');
  if (!BUNNY_STORAGE_ACCESS_KEY) missingVars.push('BUNNY_STORAGE_ACCESS_KEY');
  if (!BUNNY_PULL_ZONE_HOSTNAME) missingVars.push('BUNNY_PULL_ZONE_HOSTNAME');
  if (missingVars.length > 0) {
    throw new Error('Bunny.net upload failed: Missing environment variables: ' + missingVars.join(', '));
  }

  try {
    await axios.put(url, fileBuffer, {
      headers: {
        AccessKey: BUNNY_STORAGE_ACCESS_KEY,
        'Content-Type': 'application/octet-stream',
      },
      maxContentLength: Infinity,
      maxBodyLength: Infinity,
    });
    return getVideoUrl(storagePath);
  } catch (error) {
    let details = '';
    if (error.response) {
      details = ` (HTTP ${error.response.status}: ${JSON.stringify(error.response.data)})`;
    } else if (error.request) {
      details = ' (No response received from Bunny.net)';
    } else {
      details = ` (${error.message})`;
    }
    throw new Error('Bunny.net upload failed: ' + error.message + details);
  }
}

/**
 * Generates the CDN URL for a video file
 * @param {string} storagePath - The path inside the storage zone (e.g. lesson1.mp4 or course1/lesson1.mp4)
 * @returns {string}
 */
export function getVideoUrl(storagePath) {
  return `https://${BUNNY_PULL_ZONE_HOSTNAME}/${storagePath}`;
} 