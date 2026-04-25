#!/usr/bin/env bash
# Script: build-repo.sh
# Philosophy: Compile-on-Demand (The Factory Model)

set -euo pipefail

REPO_NAME="antisos"
SOURCE_ROOT="../antisos-ess-build"
TARGET_DIR="$(pwd)/x86_64"

mkdir -p "$TARGET_DIR"

# List of packages in the order they should be built (keyring first!)
PACKAGES=("antisos-keyring" "calamares")

echo "#######################################"
echo "   AntisOS Factory: Starting Build     "
echo "#######################################"

for pkg in "${PACKAGES[@]}"; do
    pkg_path="$SOURCE_ROOT/$pkg"
    
    if [ -d "$pkg_path" ]; then
        echo "--> Entering: $pkg"
        cd "$pkg_path"
        
        # -s: Install missing dependencies with pacman
        # -c: Clean up waste files after build
        # -f: Force rebuild even if package exists
        makepkg -scf --noconfirm
        
        echo "--> Exporting binary to $TARGET_DIR"
        mv -f *.pkg.tar.zst "$TARGET_DIR/"
        
        # Return to repo root
        cd - > /dev/null
    else
        echo "!! Warning: Directory $pkg_path not found. Skipping."
    fi
done

# --- Database Update Section ---
cd "$TARGET_DIR"

echo "--> Refreshing $REPO_NAME database..."
rm -f ${REPO_NAME}.db* ${REPO_NAME}.files*

# Add all packages found in the target dir to the DB
repo-add -n -R ${REPO_NAME}.db.tar.gz *.pkg.tar.zst

# Fix for GitHub Pages (The Symlink Fix)
mv ${REPO_NAME}.db.tar.gz ${REPO_NAME}.db
mv ${REPO_NAME}.files.tar.gz ${REPO_NAME}.files

echo "#######################################"
echo "   Build Complete & Database Updated   "
echo "#######################################"