FROM alpine:3.20.2

RUN set -x \
  && apk add --no-cache vsftpd whois shadow tzdata \
  ;

RUN set -x \
  && mkdir -p /var/run/vsftpd/empty /etc/vsftpd/user_conf /var/ftp /srv \
  && touch /var/log/vsftpd.log \
  && rm -rf /srv/ftp \
  ;

COPY vsftpd*.conf /etc/
#COPY vsftpd_virtual /etc/pam.d/
COPY *.sh /

VOLUME ["/etc/vsftpd", "/srv", "/var/log"]

EXPOSE 21 4559 4560 4561 4562 4563 4564

ENTRYPOINT ["/entry.sh"]
CMD ["vsftpd"]
