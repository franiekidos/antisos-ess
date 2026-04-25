#!/usr/bin/env bash
# Script: build-repo.sh
# Philosophy: Compile-on-Demand (The Factory Model)

set -euo pipefail

REPO_NAME="antisos"
SOURCE_ROOT="../antisos-ess-build"
TARGET_DIR="$(pwd)/x86_64"

mkdir -p "$TARGET_DIR"

# List of packages in the order they should be built (keyring first!)
PACKAGES=("antisos-keyring" "calamares" "ckbcomp")

for pkg in "${PACKAGES[@]}"; do
    pkg_path="$SOURCE_ROOT/$pkg"
    
    echo "--> Sprawdzam pakiet: $pkg"
    if [ -d "$pkg_path" ]; then
        cd "$pkg_path"
        
        # Budujemy. Jeśli makepkg zawiedzie, skrypt przerwie pracę (dzięki set -e)
        echo "--> Kompilacja: $pkg"
        makepkg -scf --noconfirm
        
        # Sprawdzenie czy plik faktycznie powstał
        BUILT_PKG=$(ls *.pkg.tar.zst 2>/dev/null | head -n 1)
        if [ -n "$BUILT_PKG" ]; then
            echo "--> Eksportuję $BUILT_PKG do $TARGET_DIR"
            mv -f "$BUILT_PKG" "$TARGET_DIR/"
        else
            echo "!! BŁĄD: Nie znaleziono gotowej paczki dla $pkg!"
            exit 1
        fi
        
        cd - > /dev/null
    else
        echo "!! BŁĄD: Folder $pkg_path nie istnieje!"
        exit 1
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