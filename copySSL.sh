#!/bin/sh

folder_name="SSL"
directory="/etc/letsencrypt/live"


if [ -d "$directory" ]; then
  cd "$directory"
	for d in */; do
		if [[ -f ./$d/privkey.pem && -f ./$d/fullchain.pem ]]; then
			echo "-- copy the new certificat to : $d"
			mkdir -p "/etc/letsencrypt/$folder_name/$d"	
			cp ./$d/cert.pem /etc/letsencrypt/$folder_name/$d/cert.pem
			cp ./$d/chain.pem /etc/letsencrypt/$folder_name/$d/chain.pem
			cp ./$d/fullchain.pem /etc/letsencrypt/$folder_name/$d/fullchain.pem
			cp ./$d/privkey.pem /etc/letsencrypt/$folder_name/$d/privkey.pem
			# combin 
			rm -f /etc/letsencrypt/$folder_name/$d/ssl.pem
			cat ./$d/cert.pem >> /etc/letsencrypt/$folder_name/$d/ssl.pem
			cat ./$d/chain.pem >> /etc/letsencrypt/$folder_name/$d/ssl.pem
			echo "" >> /etc/letsencrypt/$folder_name/$d/ssl.pem
			cat ./$d/privkey.pem >> /etc/letsencrypt/$folder_name/$d/ssl.pem
		fi
	done

	if [ ! -z "$POST_HOOK" ]; then
		echo "-- execut POST_HOOK : '$POST_HOOK'"
		eval "$POST_HOOK"
	fi
else
	echo "-- Not Find directory : $directory , exit COPY and POST_HOOK"
fi


