#!/usr/bin/env sh
# vsftpd container entrypoint script

set -e

[[ "${DEBUG}" == "true" ]] && set -x

if [[ -n "${TZ}" ]] &&
   [[ -f "/usr/share/zoneinfo/${TZ}" ]] &&
   [[ ! -e "/etc/localtime" ]]; then
  ln -s "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

# BASE_HOME, vsftpd config "user_sub_token" and the home dir for the "ftp" user
# need to be coordinated:
export BASE_HOME='/srv'
export USER_TOKEN='$USER'

if ! getent passwd ftp | grep -q ":${BASE_HOME}/${USER_TOKEN}:" ; then
  usermod --home "${BASE_HOME}/${USER_TOKEN}" ftp
fi

# Generate password if hash not set
if [[ ! -z "${FTP_PASSWORD}" ]] && [[ -z "${FTP_PASSWORD_HASH}" ]]; then
  FTP_PASSWORD_HASH="$(echo "${FTP_PASSWORD}" | mkpasswd -s -m sha-512)"
fi

if [[ ! -z "${FTP_USER}" ]] || [[ ! -z "${FTP_PASSWORD_HASH}" ]]; then
  /add-ftp-user.sh "${FTP_USER}" "${FTP_PASSWORD_HASH}"
fi

# Support multiple users
while read -r user; do
  name="${user%:*}"
  pass="${user#*:}"
  echo "User ${name}"
  /add-ftp-user.sh "${name}" "${pass}"
done < <(env | grep "^FTP_USER_" | sed 's/^FTP_USER_[a-zA-Z0-9_]*=\(.*\)/\1/')


vsftpd_stop() {
  echo "Received SIGINT or SIGTERM. Shutting down vsftpd"
  # Get PID
  pid="$(cat /var/run/vsftpd/vsftpd.pid)"
  # Set TERM
  kill -SIGTERM "${pid}"
  # Wait for exit
  wait "${pid}"
  # All done.
  echo "Done"
}

if [[ "${1}" == "vsftpd" ]]; then
  trap vsftpd_stop SIGINT SIGTERM
  echo "Running ${*}"
  "${@}" &
  pid="${!}"
  echo "${pid}" > /var/run/vsftpd/vsftpd.pid
  wait "${pid}" && exit ${?}
else
  exec "${@}"
fi
