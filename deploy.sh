#!/bin/bash

# DigitalOcean Deployment Script
# This script provides zero-downtime deployment with rollback capability

set -e  # Exit on any error

# Configuration
APP_NAME="course-platform"
DOMAIN="your-domain.com"  # Replace with your actual domain
DROPLET_IP="your-droplet-ip"  # Replace with your DigitalOcean droplet IP
DEPLOY_USER="root"
BACKUP_DIR="/backups"
APP_DIR="/opt/$APP_NAME"
DOCKER_COMPOSE_FILE="$APP_DIR/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Function to create backup
create_backup() {
    log "Creating backup..."
    
    # Create backup directory if it doesn't exist
    ssh $DEPLOY_USER@$DROPLET_IP "mkdir -p $BACKUP_DIR"
    
    # Create timestamp for backup
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_NAME="${APP_NAME}_backup_${TIMESTAMP}"
    
    # Backup current application
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && tar -czf $BACKUP_DIR/$BACKUP_NAME.tar.gz ."
    
    # Backup database (if using local MongoDB)
    # ssh $DEPLOY_USER@$DROPLET_IP "docker exec ${APP_NAME}_mongodb_1 mongodump --out /backup && docker cp ${APP_NAME}_mongodb_1:/backup $BACKUP_DIR/${BACKUP_NAME}_db"
    
    log "Backup created: $BACKUP_NAME"
}

# Function to deploy new version
deploy() {
    log "Starting deployment..."
    
    # Create backup before deployment
    create_backup
    
    # Copy new code to server
    log "Copying new code to server..."
    rsync -avz --exclude 'node_modules' --exclude '.git' --exclude 'uploads' ./ $DEPLOY_USER@$DROPLET_IP:$APP_DIR/
    
    # Copy environment file
    if [ -f .env ]; then
        scp .env $DEPLOY_USER@$DROPLET_IP:$APP_DIR/
    else
        warning "No .env file found. Make sure environment variables are set on the server."
    fi
    
    # Build and deploy on server
    log "Building and deploying on server..."
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && \
        docker-compose down && \
        docker-compose build --no-cache && \
        docker-compose up -d && \
        docker-compose logs -f --tail=50"
    
    # Wait for health check
    log "Waiting for application to be healthy..."
    sleep 30
    
    # Check if application is running
    if curl -f http://$DOMAIN/health > /dev/null 2>&1; then
        log "Deployment successful! Application is healthy."
    else
        error "Deployment failed! Application is not responding."
    fi
}

# Function to rollback
rollback() {
    log "Starting rollback..."
    
    # Get latest backup
    LATEST_BACKUP=$(ssh $DEPLOY_USER@$DROPLET_IP "ls -t $BACKUP_DIR/${APP_NAME}_backup_*.tar.gz | head -1")
    
    if [ -z "$LATEST_BACKUP" ]; then
        error "No backup found for rollback"
    fi
    
    log "Rolling back to: $LATEST_BACKUP"
    
    # Stop current application
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && docker-compose down"
    
    # Restore from backup
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && rm -rf * && tar -xzf $LATEST_BACKUP"
    
    # Restart application
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && docker-compose up -d"
    
    log "Rollback completed successfully"
}

# Function to check status
status() {
    log "Checking application status..."
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && docker-compose ps"
    
    # Check if application is responding
    if curl -f http://$DOMAIN/health > /dev/null 2>&1; then
        log "Application is healthy and responding"
    else
        warning "Application is not responding to health checks"
    fi
}

# Function to view logs
logs() {
    log "Showing application logs..."
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && docker-compose logs -f --tail=100"
}

# Function to update dependencies
update_deps() {
    log "Updating dependencies..."
    ssh $DEPLOY_USER@$DROPLET_IP "cd $APP_DIR && \
        docker-compose down && \
        docker-compose build --no-cache && \
        docker-compose up -d"
}

# Main script logic
case "$1" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    backup)
        create_backup
        ;;
    update-deps)
        update_deps
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status|logs|backup|update-deps}"
        echo ""
        echo "Commands:"
        echo "  deploy      - Deploy new version with zero downtime"
        echo "  rollback    - Rollback to previous version"
        echo "  status      - Check application status"
        echo "  logs        - View application logs"
        echo "  backup      - Create backup of current version"
        echo "  update-deps - Update dependencies"
        exit 1
        ;;
esac 