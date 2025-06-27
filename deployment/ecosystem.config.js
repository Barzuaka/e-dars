module.exports = {
  apps: [{
    name: 'course-platform',
    script: 'app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: 3001
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: '/var/log/course-platform/err.log',
    out_file: '/var/log/course-platform/out.log',
    log_file: '/var/log/course-platform/combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024',
    
    // Restart policy
    autorestart: true,
    watch: false,
    max_restarts: 10,
    min_uptime: '10s',
    
    // Logging
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    
    // Environment variables
    env_file: '.env',
    
    // Health check
    health_check_grace_period: 3000,
    
    // Kill timeout
    kill_timeout: 5000,
    
    // Listen timeout
    listen_timeout: 8000,
    
    // PM2 specific
    pmx: true,
    source_map_support: true,
    
    // Cluster mode settings
    increment_var: 'PORT',
    instance_var: 'INSTANCE_ID'
  }]
}; 