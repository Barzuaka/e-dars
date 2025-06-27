import path from 'path';
import { fileURLToPath } from 'url';

// This will be the __filename of THIS VERY FILE (paths.js inside config)
const currentFile = fileURLToPath(import.meta.url);
// This will be the __dirname of THE CONFIG FOLDER
const configDir = path.dirname(currentFile);

// This is the root directory of your project (one level up from 'config')
export const PROJECT_ROOT = path.resolve(configDir, '..');

// If you specifically need the equivalent of __dirname where app.js is (the project root)
// and intend to use it like the traditional __dirname from a file in the root:
// This might be what you're after for setting views, public folders etc. from app.js
// However, it's often better to construct paths from projectRoot.
// Let's stick to exporting projectRoot for now, which is generally more flexible.