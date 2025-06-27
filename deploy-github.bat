@echo off
echo 🚀 Deploying E-Dars via GitHub...

REM Check if we're in a git repository
if not exist ".git" (
    echo ❌ Error: Not in a git repository
    echo Please initialize git and push your code to GitHub first
    pause
    exit /b 1
)

REM Check for uncommitted changes
git diff --quiet
if %errorlevel% neq 0 (
    echo ⚠️ Warning: You have uncommitted changes
    echo Current changes:
    git status --short
    set /p commit_changes="Do you want to commit these changes? (y/n): "
    if /i "%commit_changes%"=="y" (
        git add .
        git commit -m "Auto-commit before deployment %date% %time%"
    ) else (
        echo ❌ Deployment cancelled. Please commit your changes first.
        pause
        exit /b 1
    )
)

REM Push to GitHub
echo 📤 Pushing to GitHub...
git push origin main

REM Trigger deployment on server
echo 🔧 Triggering deployment on server...
ssh root@167.172.186.30 "cd /var/www/e-dars && ./deploy-github.sh"

echo 🎉 Deployment completed!
echo 🌐 Your application should be available at: https://e-dars.uz
pause 