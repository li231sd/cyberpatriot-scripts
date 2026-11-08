#!/bin/bash

# MINT script made for cyberpatriot 19 (2026-2027) 

set -Eeuo pipefail


# TODO: Change names of admins and users

ADMINS=(
    chowe
    ellis
    mercer
    rowan
)

USERS=(
    tessa
    briar
    wells
    gideon
    beckett
    elsie
    reid
    laurel
    delaney
    rhodes
    june
    maren
)

ALL_USERS=("${ADMINS[@]}" "${USERS[@]}")

# Configs

APPLY=false
RESET_PASSWORDS=false
DELETE_HOME=false


LOG="/var/log/cyberpatriot_accounts.log"


for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=true ;;
        --reset-admin-passwords) RESET_PASSWORDS=true ;;
        --delete-home) DELETE_HOME=true ;;
        *)
            echo "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "sudo it"
    exit 1

fi

touch "$LOG"

log() {
    echo "[$(date)] $*" | tee -a "$LOG"
}

# helper functions

is_authorized() {
    local target="$1"

    for user in "${ALL_USERS[@]}"; do
        [[ "$user" == "$target" ]] && return 0
    done 

    return 1
}

is_admin() {
    local target="$1"

    for user in "${ADMINS[@]}"; do
        [[ "$user" == "$target" ]] && return 0
    done
    
    return 1
}

has_sudo() {
    id  -nG "$1" | tr ' ' '\n' | grep -qx sudo
}

change_password() {
    local user="$1"

    echo
    echo "set pwd for: $user"

    if passwd "$user"; then 
        log "pwd configed for $user"
    else
        passwd -l "$user" || true
        log "IMPORTANT: pwd setup failed + account locked: $user"
    fi
}

# main

echo "User checker"

if $APPLY; then 
    echo "m: apply changes"
else
    echo "m: dry run"
fi

echo

if ! $APPLY; then 
    echo "no modifications"
fi

declare -A NEW_USERS=()

# check if exists

log "check for auth acct"

for user in "${ALL_USERS[@]}"; do
    if getent passwd "$user" >/dev/null; then
        log "alr exists: $user"
    else 
        log "missing: $user"

        if $APPLY; then
            if useradd -m -s /bin/bash "$user"; then
                NEW_USERS["$user"]=1
                log "created $user"
            else
                log "err creating $user"
            fi
        fi
    fi
done

# enf admin priv

log "check admin priv"

for user in "${ADMINS[@]}"; do
    if ! getent passwd "$user" >/dev/null; then
        continue
    fi

    if has_sudo "$user"; then
        log "good admin: $user"
    else
        log "wowza they missing them privs: $user"

        if $APPLY; then
            usermod -aG sudo "$user"
            log "added $user to sudo"
        fi
    fi
done

# rem admin priv from std users

log "checking std user privs"

for user in "${USERS[@]}"; do
    if ! getent passwd "$user" >/dev/null; then
        continue
    fi

    if has_sudo "$user"; then
        log "unauth sudo: $user"

        if $APPLY; then
            gpasswd -d "$user" sudo
            log "rem sudo: $user"
        fi
    else 
        log "std usr ok: $user"
    fi
done

# rem unauth human accts

log "checking for unauth accts"

UID_MIN=$(awk '$1=="UID_MIN" {print $2; exit}' /etc/login.defs)
UID_MIN="${UID_MIN:-1000}"

while IFS=: read -r user password uid gid gecos home shell; do
    [[ "$uid" =~ ^[0-9]+$ ]] || continue 
    (( uid >= UID_MIN )) || continue

    # skip non-login service accts 
    [[ "$shell" == */nologin || "$shell" == */false ]] && continue

    if is_authorized "$user"; then
        continue
    fi

    log "unauth user: $user (UID $uid)"

    if $APPLY; then
        # don't remove accts with an active process
        if pgrep -u "$user" >/dev/null 2>&1; then
            log "skip $user because of active process"
            continue
        fi

        if $DELETE_HOME; then
            userdel -r "$user"
        else
            userdel "$user"
        fi

        log "rem acct: $user"
    fi

done < <(getent passwd)

# conf pwds

if $APPLY; then
    log "conf new acct pwds"

    for user in "${ALL_USERS[@]}"; do
        if [[ ${NEW_USERS[$user]+exists} ]]; then
            change_password "$user"
        fi
    done

    if $RESET_PASSWORDS; then
        log "resetting existing admin pwds"

        for user in "${ADMINS[@]}"; do
            if getent passwd "$user" >/dev/null &&
                [[ ! ${NEW_USERS[$user]+exists} ]]; then
                change_password "$user"
            fi
        done
    fi

else 
    log "skip pwd config in m: dry"
fi

# show finished stuff

echo
echo "auth admins:"
for user in "${ADMINS[@]}"; do 
    if getent passwd "$user" >/dev/null; then
        echo " $user"
    fi
done

echo
echo "saved log: $LOG"
