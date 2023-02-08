#!/bin/bash

#For this script to run correctly, the password file for mysql and postgres should be present on home directory. see below in mysql and postgres section.
#This script will backup the /var/www/, sites-enabled folder and databases[mysql and postgresql]. Run this script as a root user.

#===============Checking if the backup destination dir is present:======================
if [ ! -d /root/backups  ]
then
    mkdir /root/backups
    echo "/root/backups created successfully"
else
    echo "/root/backups already exist."
fi

date=`date '+%Y-%m-%d'`
hostname=`hostname`

#=================Backing up whole /var/www directory with few exclusions.===================================
tar --exclude={node_modules,logs,vendor,css,js,wp-includes,wp-admin,mbtiles} -czvf /root/backups/$hostname-data-$date.tar.gz /var/www/
if [ $? == 0 ]
  then
    echo "Successfully backed up data directory"
  else
    curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Data Backup [/var/www/] failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
  #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Data Backup failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
    echo "Data backup failed."
    exit 1
fi

#============Checking if apache vhost folder is present and backing up the vhosts fileif present==========
if [ -d /etc/apache2/sites-available/  ]
 then
    echo "Taking backup of apache vhost files."
    tar -czvf /root/backups/$hostname-apachevhost-$date.tar.gz /etc/apache2/sites-available/
    if [ $? == 0 ]
      then
        echo "Successfully backed up apache vhost files."
      else
        curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Apachevhost  Backup failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
      #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Apachevhost  Backup failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
        echo "Apache vhost files backup failed."
        exit 1
    fi
 else
    echo "Apache not installed."
fi

#============Checking if nginx vhost folder is present and backing up the vhosts file==========

if [ -d /etc/nginx/sites-available/ ]
  then
      echo "Taking backup of nginx vhost files."
      tar -czvf /root/backups/$hostname-nginxvhost-$date.tar.gz /etc/nginx/sites-available/
      if [ $? == 0 ]
        then
          echo "Successfully backed up nginx vhost files"
        else
          curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Nginxvhost Backup failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
        #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Nginxvhost Backup failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
          echo "Nginx vhost files backup failed."
          exit 1
      fi
  else
      echo "Nginx not installed."
      echo "No vhost file to be backed up."
fi


#DATABASE-BACKUP
#===============MYSQL======================
# The important part is not to put the password as an argument to the mysql.
# Use a .my.cnf file in the home
# dir of the user you are running this script as, i.e. /root/.my.cnf if running
# as root. Make the file readable for the owner only: chmod 400 /root/.my.cnf. below is the sample of .my.cnf file:
#[mysqldump]
#user=root
#password='3kb@n@123'
#
#[mysql]
#user=root
#password='3kb@n@123'

#Checking mysql present. If present taking each database backup.
mysql_check=`ps -aux | grep mysql | wc -l`
if [ "$mysql_check" -gt 1 ]
then
  error_result=0

  timenow=`date +%Y%m%d_%H%M%S`
  day_name=$( date +"%A" )
  day_number=$( date +"%d" )

  echo "Time now : $timenow"
  echo "Day Name : $day_name"

  echo ""
  echo "Listing the databases that we will backup ...:"
  #dblist=$( mysql --skip-column-names -u root -p$password -e "show databases" )
  dblist=$( mysql --skip-column-names -e "show databases" )

  # Test the result
  if [[ $? -eq 0 ]]; then
          echo "Successfully exported the list of Mysql Databases !"
  else
          echo "Error, unable to export the list of Mysql Databases (error code : $?)"
          error_result=1
  fi

  echo ""

  #checking if mysql-db backup destination exists.
  if [ ! -d /root/backups/mysql-db/  ]
  then
      mkdir /root/backups/mysql-db/
      echo "/root/backups/mysql-db/ created successfully"
  else
      echo "/root/backups/mysql-db/ already exist."
  fi

  # Filter the database list to exclude unnecessary databases
  dblist=$( echo "$dblist" | grep -v "^information_schema$\|^mysql$\|^performance_schema$\|^sys$" )

  if [[ "$dblist" == "" ]]; then
          echo "There is no database to backup"
  fi

  echo ""
  echo "List of databases :"
  echo "$dblist"
  echo ""
  while IFS= read -r db
  do
          if [[ "$db" != "" ]]; then

                  # Backup the DB
                  msg="Backup DB ${db} to ${db}_${timenow}.sql ..."
                  echo "$msg"
                  logger "$msg"
                  #mysqldump -u root -p$password "${db}" > "/etc/myjar_scripts/mysql_backup/${db}_${timenow}.sql"
                  #mysqldump "${db}" > "/etc/myjar_scripts/mysql_backup/${db}_${day_number}.sql"
                  mysqldump "${db}" > "/root/backups/mysql-db/${db}_${timenow}.sql"

                  # Test the result
                  if [[ $? -eq 0 ]]; then
                          echo "Success !"
                  else
                          error_level=$?
                          echo "Error Level : $error_level"
                          error_result=$(( error_result + error_level ))

                  fi
          fi
  done <<< "$dblist"

  echo "End of export"
  echo "Final result : $error_result"

  # If we have an error, send a mattermost alert
  if [[ $error_result -eq 0 ]]; then
          msg="Successful backup of the MySQL databases"
          echo "$msg"
          logger "$msg"
          #exit 0
  else
          msg="Error during the backup of the MySQL databases"
          echo "$msg"
          logger "$msg"

          msg="Sending an alert to Mattermost ..."
          echo "$msg"
          logger "$msg"
          curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Database Backup failed for '"$hostname"'  . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
        #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Database Backup failed for '"$hostname"'  . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
          echo "Database backup failed."
          exit 1
  fi

fi

#================POSTGRES==========================
#Create .pgpass in the /root/ and chmod 600. Below is pgpass sample:
##YOUR_HOST:YOUR_PORT:DB_NAME:USER_NAME:PASSWORD
#*:*:*:*:<password>


#Check for postgres and backup if present
postgres_check=`ps -aux | grep postgres | wc -l`
if [ "$postgres_check" -gt 1 ]
then
        # Location to place backups.
        backup_dir="/root/backups/postgres-db/"
        #String to append to the name of the backup files
        backup_date=`date +%Y-%m-%d`

        if [ ! -d /root/backups/postgres-db/  ]
        then
          mkdir /root/backups/postgres-db/
          echo "/root/backups/postgres-db/ created successfully"
        else
          echo "/root/backups/postgres-db/ already exist."
        fi


  #Getting databasse list.
  databases=$( psql -h 127.0.0.1 -U postgres -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' )

	if [[ $? -eq 0 ]]; then
          echo "Successfully exported the list of postgres Databases !"
  else
          echo "Error, unable to export the list of postgres Databases (error code : $?)"
          error_result=1
  fi

  echo ""

  #Filter database list to exclude unnecessary database.
  databases=$( echo "$databases" | grep -v template | grep -v postgres )

  #Taking postgres databases backup.
	if [ "$databases" == "" ]; then
                echo "There is no database to backup"
              #  exit 0
        fi

        echo ""
        echo "List of Postgres databases :"
        echo "$databases"
        echo ""
        while IFS= read -r pg
        do
                if [[ "$pg" != "" ]]; then
                  echo Dumping $pg to $backup_dir${pg}_${backup_date}.sql
                  pg_dump -h 127.0.0.1 -U postgres  -Fc ${pg} > $backup_dir${pg}_${backup_date}.sql
                  #restore eg: pg_restore [-P 5433] -1 <dbbackup>_2019-05-14.sql -d <dbname>
		              if [[ $? -eq 0 ]]; then
                          echo "Success !"
                  else
                          error_level=$?
                          echo "Error Level : $error_level"
                          error_result=$(( error_result + error_level ))

                  fi
                fi
        done <<< "$databases"

	      echo "End of export"
        echo "Final result : $error_result"

        # If we have an error, send a mattermost alert
        if [[ $error_result -eq 0 ]]; then
             msg="Successful backup of the Postgres databases"
             echo "$msg"
             logger "$msg"
             #exit 0
        else
             msg="Error during the backup of the Postgres databases"
             echo "$msg"
             logger "$msg"

             msg="Sending an alert to Mattermost ..."
             echo "$msg"
             logger "$msg"
             curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Database Backup failed for '"$hostname"'  . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
           #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Database Backup failed for '"$hostname"'  . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
             echo "Database backup failed."
             exit 1
       fi
fi

#==================MONGODB==========================

mongo_check=`ps -aux | grep mongo | wc -l`
if [ "$mongo_check" -gt 1 ]
then
   mongodb_list=$( echo "db.getMongo().getDBNames()"|mongo --quiet |tr -d \[\ \ \] | tr , "\n"|cut -c2-| tr -d \" )


  if [[ $? -eq 0 ]]; then
          echo "Successfully exported the list of mongodb Databases !"
  else
          echo "Error, unable to export the list of mongodb Databases (error code : $?)"
          error_result=1
  fi

  echo ""

  #checking if mongodb backup destination exists.
  if [ ! -d /root/backups/mongo-temp/  ]
  then
      mkdir /root/backups/mongo-temp/
      echo "/root/backups/mongo-temp/ created successfully"
  else
      echo "/root/backups/mongo-temp/ already exist."
  fi

  mongodb_list=$( echo "$mongodb_list" | grep -v local )

  if [[ "$mongodb_list" == "" ]]; then
          echo "There is no database to backup"
          exit 0
  fi

  echo ""
  echo "List of mongodb databases :"
  echo "$mongodb_list"
  echo ""

while IFS= read -r mongodb
  do
          if [[ "$mongodb" != "" ]]; then
		msg="Backup DB ${mongodb} ..."
                  echo "$msg"
                  logger "$msg"
		  mongodump -d "${mongodb}" -o /root/backups/mongo-temp/

		# Test the result
                  if [[ $? -eq 0 ]]; then
                          echo "Success !"
                  else
                          error_level=$?
                          echo "Error Level : $error_level"
                          error_result=$(( error_result + error_level ))

                  fi
	  fi
done <<< "$mongodb_list"

  echo "End of export"
  echo "Final result : $error_result"

  # If we have an error, send a mattermost alert
  if [[ $error_result -eq 0 ]]; then
          msg="Successful backup of the mongo databases"
          echo "$msg"
          logger "$msg"
          #exit 0
  else
          msg="Error during the backup of the mongo databases"
          echo "$msg"
          logger "$msg"

          msg="Sending an alert to Mattermost ..."
          echo "$msg"
          logger "$msg"
          curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Mongodb database Backup failed for '"$hostname"'  . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
        #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Database Backup failed for '"$hostname"'  . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
          echo "Mongodb Database backup failed."
          exit 1
  fi
  #Compressing mongo-temp file and keeping it datewise
  mkdir -p /root/backups/mongo-db
  tar -czvf /root/backups/mongo-db/mongo-db-${date}.tar.gz /root/backups/mongo-temp/
  rm -r /root/backups/mongo-temp/
fi



#===============Transfer backup to remote server=========================

rsync -ave 'ssh -p 3030' -r /root/backups/* root@ek-nagios.ekbana.info:/mnt/volume-blr1-01/backup_folder/${hostname}
if [ $? == 0 ]
  then
    echo "Successfully transferred to backup server."
    rm -r /root/backups/
  else
    curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Transferring to Backup server failed for '"$hostname"' . Exiting the backup process...Please check the log file at /var/log/backup.log"}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
    echo "Transfer to backup server failed."
    exit 1
fi

# ==================Mattermost Notification for successful backup===================
    curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Backup of '"$hostname"' has been completed successfully."}' https://ekbana.letsperk.com/hooks/cn8e8hya5tdtbrb3mx1tmjwksw
  #  curl -i -X POST -H 'Content-Type: application/json' -d '{"text": "'"$date"' : Backup of '"$hostname"' has been completed successfully."}' https://ekbana.letsperk.com/hooks/sm5ayypzqbrwdqbwes8oedfmyy
    echo "Backup Successful"

