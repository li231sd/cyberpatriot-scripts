#!/bin/bash
LOG_FILE="/tmp/unauthorized_media.txt"
echo "Searching for unauthorized media files" > "$LOG_FILE"
find /home /root -type f \( -name "*.mp3" -o -name "*.mp4" -o -name "*.wav" -o -name "*.avi" -o -name "*.mkv" -o -name "*.torrent" \) >> "$LOG_FILE"

echo "Media scan complete. Log saved to $LOG_FILE"
find /home /root -type f \( -name "*.mp3" -o -name "*.mp4" -o -name "*.wav" -o -name "*.avi" -o -name "*.mkv" -o -name "*.torrent" \) -delete

HACKING_TOOLS=("nmap" "wireshark" "john" "hydra" "ophcrack" "aircrack-ng" "nikto" "netcat" "nc")
for tool in "${HACKING_TOOLS[@]}"; do
    if dpkg -l | grep -q "$tool"; then
        echo "Rem prohibited package: $tool"
        apt-get purge -y "$tool"
    fi
done

apt-get autoremove -y
apt-get clean
