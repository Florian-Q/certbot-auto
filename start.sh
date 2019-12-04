#!/bin/sh

if [ -z "$DOMAINS" ]; then
  echo "No domains set, please fill -e 'DOMAINS=example.com www.example.com'"
  exit 1
fi

if [ ! -z "$WEBROOT_PATH" ]; then
	echo "* mod 'webroot' to : '$WEBROOT_PATH', bandage to configure your webserver"
    parameter="--webroot --webroot-path '$WEBROOT_PATH'"
else
    echo "* mod 'standalone', bandage to open the port 80 or 443"
    parameter="--standalone"
fi

if [ ! -z "$PREFERRED_CHALLENGES" ]; then
	echo "* preferred-challenges set to : $PREFERRED_CHALLENGES"
    parameter="$parameter --preferred-challenges $PREFERRED_CHALLENGES"
fi

if [ ! -z "$RSA_KEY_SIZE" ]; then
	echo "* rsa-key-size set to : $RSA_KEY_SIZE"
    parameter="$parameter --rsa-key-size $RSA_KEY_SIZE"
else
    echo "* default value of rsa-key-size is 2048"
fi

if [ ! -z "$MAX_LOG_BACKUPS" ]; then
    echo "* max-log-backups set to : $MAX_LOG_BACKUPS"
    parameter="$parameter --max-log-backups $MAX_LOG_BACKUPS"
fi

if [ ! -z "$PRE_HOOK" ]; then
	echo "* pre-hook set : '$PRE_HOOK'"
    parameter="$parameter --pre-hook '$PRE_HOOK'"
fi

if [ ! -z "$POST_HOOK" ]; then
	echo "* post-hook set : '$POST_HOOK'"
fi
parameter="$parameter --post-hook /copySSL.sh --noninteractive"
parameterRenew="$parameter"

if [ ! -z "$AUTER_OPTION" ]; then
	echo "* auter option on create (is skipping if certs exist): $AUTER_OPTION"
    parameter="$parameter $AUTER_OPTION"
fi

if [ -z "$EMAIL" ]; then
    echo "* No email set, you can use : 'certbot update_account --email youreamil@example.com'"
    echo "  in the container, to modify your email at any time"
else
	parameter="$parameter --email $EMAIL --no-eff-email"
fi

echo "* certificates status :"
status=$(certbot certificates)
echo "$status"

if [ $(echo $status | grep -c 'No certs found.') -gt 0 ]; then

    # Create new certificat
    for word in $DOMAINS
    do
        parameter="$parameter -d $word"
    done
    cmdCreat="certbot certonly $parameter --agree-tos"
    echo ""
    echo "* new certificates create cmd : $cmdCreat"

    eval "$cmdCreat"
fi

if [ ! -z "$CRON" ]; then
    echo "* cron job set to : $CRON"
    # create script to renew command
    echo '#!/bin/sh' > /etc/crontabs/cron.sh
    # filter to add date and remove 2 firt line (Saving debug log to /var/log/letsencrypt/letsencrypt.log)
    filtreLog="awk -v date=\"\$(date +\"%Y-%m-%d_%H-%M-%S\")\" '{if (NR>2) {print}; if (NR==2) {print \"# \",date}}'"
    echo "certbot renew $parameterRenew 2>&1 | $filtreLog" >> /etc/crontabs/cron.sh
    chmod +x /etc/crontabs/cron.sh
    # add auto execute script in cron job
    echo "$CRON /etc/crontabs/cron.sh >> /var/log/letsencrypt/cron.log" > /etc/crontabs/root
else 
    echo "* No cron time set, not cron job use to renew and stop the container"
    exit 0
fi

exec "$@"