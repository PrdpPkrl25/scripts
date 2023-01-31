#!/bin/bash
loop=1
cd /etc/nginx/sites-available
while [ $loop -eq 1 ]
do
echo "Input Domain name:"
read -e domain
echo "Provide the path:"
read -e path
echo "server {
       
       server_name $domain;

       root $path;
       index index.html index.php;

       location / {
               try_files $uri $uri/ /index.php?$args;
       }
       
       access_log /var/log/nginx/$domain.access.log;
       error_log /var/log/nginx/$domain.error.log;

}" > /etc/nginx/sites-available/$domain.conf
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
