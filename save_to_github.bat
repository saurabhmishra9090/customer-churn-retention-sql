
@echo off
title Customer Churn - GitHub Save

echo.
echo ==========================================
echo   CUSTOMER CHURN - GITHUB SAVE SYSTEM
echo ==========================================
echo.

:: Check Git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERROR: Not inside a Git repository.
    pause
    exit /b 1
)

:: Show current changes
echo Current project status:
git status --short
echo.

:: Ask for commit message
set /p "msg=Enter commit message: "

if "%msg%"=="" (
    echo ERROR: Commit message cannot be empty.
    pause
    exit /b 1
)

:: Confirm before saving
echo.
set /p "confirm=Continue with GitHub save? (Y/N): "

if /i not "%confirm%"=="Y" (
    echo Save cancelled.
    pause
    exit /b 0
)

:: Stage all changes
git add -A

if errorlevel 1 (
    echo ERROR: Git add failed.
    pause
    exit /b 1
)

:: Check whether there are changes to commit
git diff --cached --quiet
if not errorlevel 1 (
    echo.
    echo No new changes to commit.
    pause
    exit /b 0
)

:: Commit changes
git commit -m "%msg%"

if errorlevel 1 (
    echo ERROR: Commit failed.
    pause
    exit /b 1
)

:: Push to GitHub
git push origin main

if errorlevel 1 (
    echo.
    echo Push failed. Your commit is saved locally.
    echo Fix the issue and run this script again.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo   SUCCESS! PROJECT PUSHED TO GITHUB
echo ==========================================
echo.

git status --short
pause
