#!/bin/bash
echo "Fixing standard system permissions"

chmod 644 /etc/passwd
chown root:root /etc/passwd

chmod 640 /etc/shadow
chown root:shadow /etc/shadow

chmod 644 /etc/group
chown root:root /etc/group

chmod 640 /etc/gshadow
chown root:shadow /etc/gshadow

chmod 440 /etc/sudoers
chown root:root /etc/sudoers

chmod -R 750 /etc/sudoers.d/
chown -R root:root /etc/sudoers.d/

find / -maxdepth 3 -not -path "/proc/*" -not -path "/sys/*" -type f -perm -0002 -exec ls -l {} + > /tmp/world_writable.txt
