#On reboot script will always run to back up youre favorite folder



sudo crontab -e
#modify username in scripts
#add this line to crontab

@reboot /home/<user name>/Desktop/desky/scripts/backup/backup.sh >> /home/kula/Desktop/desky/scripts/backup/backup_log.txt 2>&1