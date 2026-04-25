#!/usr/bin/env bash
# Script: build-repo.sh
# Purpose: Move built packages from Ess-Build to Repo and update DB

set -euo pipefail

REPO_NAME="antisos"
SOURCE_DIR="../antisos-ess-build/"
TARGET_DIR="x86_64"

# 1. Check if source exists to prevent errors
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: $SOURCE_DIR not found. Build your packages first!"
    exit 1
fi

# 2. Move the packages
echo "#######################################"
echo "Moving packages from Essentials Build"
echo "#######################################"

# Find .zst packages and moves them. Using -f to overwrite if you rebuilt a version.
find "$SOURCE_DIR" -type f -name "*.pkg.tar.zst*" | while read -r pkg; do
    echo "--> Moving: $(basename "$pkg")"
    mv -f "$pkg" "$TARGET_DIR/"
done

# 3. Enter the target and rebuild DB
cd "$TARGET_DIR"

echo "--> Cleaning old database files..."
rm -f ${REPO_NAME}*

echo "--> Rebuilding the database..."
# I've removed -s (signing) for now to ensure it builds 
# without stopping for a GPG password. Add it back when ready!
repo-add -n -R ${REPO_NAME}.db.tar.gz *.pkg.tar.zst

# 4. Finalize for GitHub Pages (The GitLab/GitHub Symlink Fix)
rm -f ${REPO_NAME}.db ${REPO_NAME}.files
mv ${REPO_NAME}.db.tar.gz ${REPO_NAME}.db
mv ${REPO_NAME}.files.tar.gz ${REPO_NAME}.files

echo "#######################################"
echo "Success: AntisOS Repo is ready to push!"
echo "#######################################"