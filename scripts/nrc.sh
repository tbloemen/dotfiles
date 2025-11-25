#!/bin/bash
set -euo pipefail

# 1. Configuration – Edit these:
NRC_USER="casbloem%40hetnet.nl"
NRC_PASS="Vuilniszak2!"
DOWNLOAD_DIR="/home/ties/Downloads/nrc_epubs"
RCLONE_REMOTE="gdrivegroover" # Name of your rclone remote (configured with `rclone config`)
RCLONE_PATH="krant"           # Path inside remote where epubs go
DATE=$(date +%Y%m%d)
FILENAME="nrc_${DATE}.epub"
URL="https://login.nrc.nl/login?service=http://digitaleeditie.nrc.nl/digitaleeditie/helekrant/epub/${FILENAME}"

# 2. Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 3. Download the NRC epub
wget -O "$FILENAME" --keep-session-cookies \
  --post-data="username=$NRC_USER&password=$NRC_PASS" \
  "$URL"

# 4. Sync to Google Drive via rclone
# Copy only new or changed files
rclone copy "$DOWNLOAD_DIR/" "${RCLONE_REMOTE}:${RCLONE_PATH}/" \
  --update --create-empty-src-dirs --no-traverse --progress

# 5. Optional: prune old files (e.g., older than 30 days)
find "$DOWNLOAD_DIR" -type f -name "nrc_*.epub" -mtime +30 -delete
rclone delete "${RCLONE_REMOTE}:${RCLONE_PATH}" --min-age 30d

echo "Downloaded $FILENAME and synced to remote."
