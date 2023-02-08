#!/usr/bin/env python
import os
import sys
import apt
import readline


def vhost(domain,path):
        try:
                with open(f'/etc/apache2/sites-available/{domain}.conf', 'w') as f:
                        f.write(f'<VirtualHost *:80> \n' + 
                                f'       ServerName {domain} \n' +
                                f'       ServerAlias www.{domain} \n' +
                                 '        ServerAdmin devops@ekbana.info \n' +
                                f'       DocumentRoot {path} \n' +
                                f'<Directory {path}> \n'+
                                 '        Options FollowSymLinks \n' +
                                 '        AllowOverride All \n' +
                                 '        Require all granted \n' +
                                 '</Directory> \n' +
                                f'ErrorLog /var/log/apache2/{domain}_error.log \n' +
                                f'CustomLog /var/log/apache2/{domain}_access.log combined \n' +
                                 '</VirtualHost> \n')
        except (OSError, IOError) as exc:
                print("Failed to create vhost.")
                sys.exit()
        else:
                f.close()
                print("vhost created successfully.")

        try:
                os.system("sudo apachectl configtest")
        except:
                print("Configtest failed.Please check vhost file")
                sys.exit()
        else:
                os.system(f"a2ensite {domain}.conf")
                os.system("sudo service apache2 reload")
                cache = apt.Cache()
                if not cache['python3-certbot-apache'].is_installed:
                        os.system("apt install certbot python3-certbot-apache -y")
                val=input(f"Going to issue certificate for {domain}. Please make sure dns record is present.... Press y to continue:")
                if val=='y' or val=='Y':
                        os.system(f"certbot run -n --apache --agree-tos -d {domain}  -m  devops@ekbana.info  --redirect")
                else:
                        print(f"vhost has been created for {domain}, Please run certbot manually")



if __name__=="__main__":
        status=True
        os.chdir("/etc/apache2/sites-available")
        readline.set_completer_delims(' \t\n=')
        readline.parse_and_bind("tab: complete")
        while(status):
                domain=input('Input Domain name:\n')
                path=input('Provide the path:\n')
                vhost(domain,path)
                val=input('Do you want to create another vhost[y/n]?:')
                if val=='n' or val=='N':
                     status = False   
                
        