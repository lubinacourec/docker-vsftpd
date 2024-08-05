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
if ! stat -c "%U:%G" "${BASE_HOME}/${username}" | grep -q "^ftp:ftp$" ; then
  echo "Changing owner for the new home dir to ftp..."
  chown ftp:ftp "${BASE_HOME}/${username}"
fi
