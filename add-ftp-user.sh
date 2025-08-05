#!/usr/bin/env sh
# Adds a ftp user

set -e

[[ "${DEBUG}" == "true" ]] && set -x

if [[ "${#}" -lt 2 ]] || [[ "${#}" -gt 3 ]]; then
  echo "Usage: $0 <user> <password>" >&2
  echo >&2
  exit 1
fi

username="$1"
pass_hash="$2"

if ! getent passwd "${username}" > /dev/null ; then
  echo "Adding user ${username}..."
  adduser -h "${BASE_HOME}/${username}" -g "${username}" -s /sbin/nologin -G ftp -D "${username}"
fi
if ! getent shadow "${username}" | grep -q ":${pass_hash}:" ; then
  echo "Setting ${username} hash password..."
  echo "${username}:${pass_hash}" | chpasswd -e
fi
### for writable_chroot=no this dir should be unwritable, and a writable directory created inside it for files
if ! stat -c "%U:%G" "${BASE_HOME}/${username}" | grep -q "^root:root$" ; then
  echo "Changing owner for the new home dir to root..."
  chown root:root "${BASE_HOME}/${username}"
fi
