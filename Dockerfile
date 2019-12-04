FROM certbot/certbot:latest

RUN apk --no-cache add docker 

ADD start.sh /start.sh
ADD copySSL.sh /copySSL.sh
RUN chmod +x /copySSL.sh

# VOLUME ["/etc/letsencrypt" "/var/log/letsencrypt" "/var/run/docker.sock"] 

ENTRYPOINT ["/bin/sh", "/start.sh"]
CMD [ "crond", "-l", "2", "-f" ]

# inspire to : https://github.com/kvaps/docker-letsencrypt-webroot
