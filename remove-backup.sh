find /mnt/volume-blr1-01/backup_folder/project/ -maxdepth 1 -iname '*.tar.gz' -mtime +1 -exec rm {} \;
find /mnt/volume-blr1-01/backup_folder/project/*/ -type f -mtime +7 -exec rm {} \;

