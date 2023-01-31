#!/bin/bash
loop=1
cd /etc/nginx/sites-available
while [ $loop -eq 1 ]
do
echo "Input Domain name:"
read -e domain
echo "Provide the port:"
read -e port
echo 'server {

	index index.html index.htm index.nginx-debian.html;

	server_name '$domain' www.'$domain';
	include /etc/nginx/conf.d/*.conf;
	location / {
	proxy_pass http://localhost:'$port';
	proxy_http_version 1.1;
	proxy_set_header Host $host;

	proxy_set_header X-Original-Host $http_host;
	proxy_set_header X-Original-Scheme $scheme;
	proxy_set_header X-Forwarded-For $remote_addr;
        }
        
        access_log /var/log/nginx/'$domain'.access.log;
        error_log /var/log/nginx/'$domain'.error.log;
}' > /etc/nginx/sites-available/$domain.conf
if [ $? -eq 0 ];then
        echo "vHost created successfully."
else
        echo "Failed to create vHost."
        exit 1
fi
nginx -t
if [ $? -eq 0 ];then
        sudo ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
else
        echo "Configtest failed.Please check vhost file"
        exit 1
fi
sudo service nginx reload
apt list --installed 2>/dev/null  | grep certbot 1>/dev/null
if [[ $? -ne 0 ]];then
	 apt install certbot python3-certbot-nginx -y
fi
echo "Going to issue certificate for $domain. Please make sure dns record is present.... Press y to continue"
read -e input
if [[ $input == y ]]; then
	certbot run -n --nginx --agree-tos -d $domain  -m  devops@ekabana.info  --redirect
else
	echo "vhost has been created for $domain, Please run certbot manually"
fi
echo "Do you want to create another vhost[y/n]?:"
read -e input
if [ $input != y ] ; then
        loop=2
fi
done
#sudo service nginx reload
