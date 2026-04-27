#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="antisos"
SOURCE_ROOT="../antisos-ess-build"
TARGET_DIR="$(pwd)/x86_64"

mkdir -p "$TARGET_DIR"
PACKAGES=("antisos-keyring" "antisos-installer")

for pkg in "${PACKAGES[@]}"; do
    pkg_path="$SOURCE_ROOT/$pkg"
    
    if [ -d "$pkg_path" ]; then
        cd "$pkg_path"
        echo "--> Kompilacja i podpisywanie: $pkg"
        
        # Dodajemy --sign, aby podpisać paczkę podczas budowy
        makepkg -scf --sign --noconfirm
        
        echo "--> Eksportuję paczki i podpisy do $TARGET_DIR"
        # KLUCZOWA ZMIANA: Przenosimy plik .zst ORAZ .sig
        mv -f *.pkg.tar.zst* "$TARGET_DIR/"
        
        cd - > /dev/null
    else
        echo "!! BŁĄD: Folder $pkg_path nie istnieje!"
        exit 1
    fi
done

# --- Database Update Section ---
cd "$TARGET_DIR"

echo "--> Refreshing $REPO_NAME database..."
# Czyścimy stare pliki bazy, ale ZOSTAWIAMY pliki .sig paczek
rm -f ${REPO_NAME}.db* ${REPO_NAME}.files*

# Dodajemy flagę -s do repo-add, aby podpisać samą bazę danych
repo-add -s -n -R ${REPO_NAME}.db.tar.gz *.pkg.tar.zst

# Fix dla GitHub Pages (Symlink Fix) - Musimy przenieść też podpisy bazy!
rm -f ${REPO_NAME}.db ${REPO_NAME}.files

mv ${REPO_NAME}.db.tar.gz ${REPO_NAME}.db
mv ${REPO_NAME}.db.tar.gz.sig ${REPO_NAME}.db.sig
mv ${REPO_NAME}.files.tar.gz ${REPO_NAME}.files
mv ${REPO_NAME}.files.tar.gz.sig ${REPO_NAME}.files.sig

echo "#######################################"
echo "   Build Complete & Database Signed    "
echo "#######################################"