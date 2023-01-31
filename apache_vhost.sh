#!/bin/bash
loop=1
cd /etc/apache2/sites-available
while [ $loop -eq 1 ]
do
echo "Input Domain name:"
read -e domain 
echo "Provide the path:"
read -e path
echo "<VirtualHost *:80>
       ServerName $domain
       ServerAlias www.$domain
        ServerAdmin devops@ekbana.info
        DocumentRoot $path
<Directory $path>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
        ErrorLog /var/log/apache2/${domain}_error.log
        CustomLog /var/log/apache2/${domain}_access.log combined
</VirtualHost>" > /etc/apache2/sites-available/$domain.conf
if [ $? -eq 0 ];then
        echo "vHost created successfully."
else
        echo "Failed to create vHost."
        exit 1
fi
apachectl configtest
if [ $? -eq 0 ];then
        a2ensite $domain.conf
else
        echo "Configtest failed.Please check vhost file"
        exit 1
fi
service apache2 reload
apt list --installed 2>/dev/null  | grep python3-certbot-apache 1>/dev/null
if [[ $? -ne 0 ]];then
	 apt install certbot python3-certbot-apache -y
fi
echo "Going to issue certificate for $domain. Please make sure dns record is present.... Press y to continue"
read -e input
if [[ $input == y ]]; then
	certbot run -n --apache --agree-tos -d $domain  -m  devops@ekabana.info  --redirect
else
	echo "vhost has been created for $domain, Please run certbot manually"
fi
echo "Do you want to create another vhost[y/n]?:"
read -e input
if [ $input != y ] ; then
        loop=2
fi
done
#service apache2 reload
