# Dump the mysql database
mysqldump -u user -ppassword --all-databases --routines | gzip > /pathToBackup/mysqlBackup_`date +"%m-%d-%Y"`.sql.gz
# Remove the backups older than 7 days
find /pathToBackup/mysqlBackup/* -name "*.sql.gz" -mtime +7 -exec rm -vf {} \;

