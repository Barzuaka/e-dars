## Running the Project with Docker

This project is fully containerized and can be run using Docker Compose. Below are the project-specific instructions and requirements for running the application in a Dockerized environment.

### Project-Specific Docker Requirements
- **Node.js Version:** The application uses Node.js version `22.13.1` (as specified in the Dockerfile).
- **MongoDB:** The project depends on a MongoDB service, which is included in the `docker-compose.yml`.

### Environment Variables
- The application expects environment variables to be set via a `.env` file. The `docker-compose.yml` includes a commented `env_file: ./.env` line. If your project requires environment variables, ensure you have a `.env` file in the project root.

### Exposed Ports
- **Application:** Exposes port `3001` (host:container mapping `3001:3001`).
- **MongoDB:** Exposes port `27017` (host:container mapping `27017:27017`).

### Build and Run Instructions
1. **(Optional) Prepare your `.env` file:**
   - If your application requires environment variables, create a `.env` file in the project root. Refer to the `.env` sample or documentation for required variables.
2. **Build and start the services:**
   ```sh
   docker compose up --build
   ```
   This will build the Node.js application image and start both the app and MongoDB containers.
3. **Access the application:**
   - The app will be available at [http://localhost:3001](http://localhost:3001)
   - MongoDB will be accessible at `localhost:27017` for development purposes.

### Special Configuration
- **Uploads Directory:** The Dockerfile ensures that `public/uploads/gallery` and `public/uploads/thumbnails` directories are created with appropriate permissions.
- **Non-root User:** The application runs as a non-root user inside the container for improved security.
- **Healthchecks:** Both the app and MongoDB containers have healthchecks configured for better orchestration support.
- **MongoDB Data Persistence:**
  - By default, MongoDB data is not persisted. To enable persistence, uncomment the `volumes` section for `mongo` in `docker-compose.yml`.

### Additional Notes
- The application is served in production mode (`NODE_ENV=production`).
- If you need to customize the Node.js memory limit, it is set via `NODE_OPTIONS` in the Dockerfile.

For more detailed deployment instructions, refer to `DEPLOYMENT_GUIDE.md` in the project root.