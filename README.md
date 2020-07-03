# Let’s Encrypt (webroot) in a Docker with cron jobs

## Usage

* First, you need to set up your web server so that it gave the contents of the `/.well-known/acme-challenge` directory properly. 
  Example, for nginx add location for your server:
```nginx
    location '/.well-known/acme-challenge' {
        default_type "text/plain";
        root        /tmp/letsencrypt;
    }
```
* Then run your web server image with letsencrypt-webroot connected volumes:
```bash
   -v /data/letsencrypt/SSL:/etc/cert # juste certificate 
   -v /tmp/challenges:/tmp/letsencrypt
```
* Run letsencrypt-webroot image:
```bash
   docker run \
     --name some-letsencrypt \
     -v /data/letsencrypt:/etc/letsencrypt \
     -v /tmp/challenges:/tmp/letsencrypt \
     -e 'DOMAINS=example.com www.example.com' \
     -e 'EMAIL=your@email.tld' \
     -e 'WEBROOT_PATH=/tmp/letsencrypt' \
     florianq/certbot-cron
```

* Configure your app to use certificates in the following path:

  * **Private key**: `/etc/cert/example.com/privkey.pem`
  * **Certificate**: `/etc/cert/example.com/cert.pem`
  * **Intermediates**: `/etc/cert/example.com/chain.pem`
  * **Certificate + intermediates**: `/etc/letsencrypt/live/example.com/fullchain.pem`


## Renew hook

You can also assign hook for your container, it will be launched after letsencrypt receive a new certificate.

* This feature requires a passthrough docker.sock into letsencrypt container: `-v /var/run/docker.sock:/var/run/docker.sock`
* Also add `--link` to your container. Example: `--link some-nginx`
* Then add `LE_RENEW_HOOK` environment variable to your container:

Example hooks:
  - nginx reload: `-e 'LE_RENEW_HOOK=docker kill -s HUP @CONTAINER_NAME@'`
  - container restart: `-e 'LE_RENEW_HOOK=docker restart @CONTAINER_NAME@'`

For more detailed example, see the docker-compose configuration

## Docker-compose

This is example of letsencrypt-webroot with nginx configuration:

`docker-compose.yml`
```yaml
version: '3'

volumes:
  challenges:

nginx:
  restart: always
  image: nginx
  volumes:
    - ./web/nginx:/etc/nginx/conf.d
    - ./web/letsencrypt/SSL:/SSL
    - ./logs/nginx:/var/log/nginx
    - challenges:/var/www/letsencrypt
  environment:
    - TZ=Europe/Paris
  ports:
    - 80:80
    - 443:443
  networks:
    - webproxy

letsencrypt:
  restart: always
  image: florianq/certbot-cron
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - ./web/letsencrypt:/etc/letsencrypt
    - ./logs/letsencrypt:/var/log/letsencrypt
    - challenges:/tmp/letsencrypt
  environment:
    - CRON=22 0 * * 0
    - TZ=Europe/Paris
    - DOMAINS=example.com www.example.com
    - EMAIL=your@email.tld
    - WEBROOT_PATH=/tmp/letsencrypt
    - RSA_KEY_SIZE=4096
    - POST_HOOK=docker restart nginx
    - MAX_LOG_BACKUPS=30
  depends_on:
    - nginx
  networks:
    - webproxy
```


## Environment variables

* **DOMAINS**: Domains for your certificate. Example to `example.com www.example.com`.
* **EMAIL**: Email for urgent notices and lost key recovery. Example to `your@email.tld`.
* **WEBROOT_PATH** Path to the letsencrypt directory in the web server for checks. Example to `/tmp/letsencrypt`.
* **CHOWN** Owner for certs. Defaults to `root:root`.
* **CHMOD** Permissions for certs. Defaults to `644`.
* **EXP_LIMIT** The number of days before expiration of the certificate before request another one. Defaults to `30`.
* **CHECK_FREQ**: The number of days how often to perform checks. Defaults to `30`.
* **CHICKENEGG**: Set this to 1 to generate a self signed certificate before attempting to start the process with no previous certificate. Some http servers (nginx) might not start up without a certificate file present.
* **STAGING**: Set this to 1 to use the staging environment of letsencrypt to prevent rate limiting while working on your setup.
