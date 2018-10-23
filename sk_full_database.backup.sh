#!/bin/bash
# mysql_backup.sh: backup mysql databases and keep newest 5 days backup.
#
# ${db_user} is mysql username
# ${db_password} is mysql password
# ${db_host} is mysql host
#/root/mysql_backup.sh
# everyday 3:00 AM execute database backup
# 0 3 * * * /root/mysql_backup.sh
#/etc/cron.daily

db_user="root"
db_password="abcdefghijklmnopqrst"
db_host="localhost"
# the directory for story your backup file.  #
backup_dir="/data/backup/mysql"

#all_db="dbname"

backup_day=10

logfile="/var/log/mysql_backup.log"

# date format for backup file (dd-mm-yyyy)  #
time="$(date +"%Y-%m-%d")"

# mysql, ${mysqldump} and some other bin's path  #
mysql="/usr/bin/mysql"
mysqldump="/usr/bin/mysqldump"

all_db="$(${mysql} -u ${db_user} -h ${db_host} -p${db_password} -Bse 'show databases')" #
# the directory for story the newest backup  #
test ! -d ${backup_dir} && mkdir -p ${backup_dir}

mysql_backup()
{
    for db in ${all_db}
    do
        backname=${db}.${time}
        dumpfile=${backup_dir}/${backname}

        echo "------"$(date +'%Y-%m-%d %T')" Beginning database "${db}" backup--------" >>${logfile}
        ${mysqldump} -F -u${db_user} -h${db_host} -p${db_password} --default-character-set=utf8 ${db} > ${dumpfile}.sql 2>>${logfile} 2>&1

        echo $(date +'%Y-%m-%d %T')" Beginning zip ${dumpfile}.sql" >>${logfile}
        tar -czvf ${backname}.tar.gz ${backname}.sql 2>&1 && rm ${dumpfile}.sql 2>>${logfile} 2>&1

        echo "backup file name:"${dumpfile}".tar.gz" >>${logfile}
        echo -e "-------"$(date +'%Y-%m-%d %T')" Ending database "${db}" backup-------\n" >>${logfile}
    done
}

delete_old_backup()
{
    echo "delete backup file:" >>${logfile}
    find ${backup_dir} -type f -mtime +${backup_day} | tee delete_list.log | xargs rm -rf
    cat delete_list.log >>${logfile}
}


cd ${backup_dir}

mysql_backup
delete_old_backup

echo -e "========================mysql backup && rsync done at "$(date +'%Y-%m-%d %T')"============================\n\n">>${logfile}
cat ${logfile}
