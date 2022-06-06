#!/bin/bash

/usr/bin/freshclam > /dev/null 2>&1

LOCKFILE=/tmp/maldet_lock.txt
MYPID=$$
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
BACKUP_EDITOR=$EDITOR
export EDITOR=cat
if [ -e $LOCKFILE ]; then
        if [ ! -d /proc/`cat $LOCKFILE` ]; then
                echo "Stale PID file, cleaning..."
                /bin/rm -f $LOCKFILE
                /bin/rm -f $POSTFILE
        else
                /bin/echo "Someone else running, exiting..."
                exit 1
        fi
fi
echo $MYPID > $LOCKFILE
grep -q $MYPID $LOCKFILE || exit 1

# clear quarantine/session/tmp data every 14 days
/usr/sbin/tmpwatch 336 /usr/local/maldetect/tmp >> /dev/null 2>&1
/usr/sbin/tmpwatch 336 /usr/local/maldetect/sess >> /dev/null 2>&1
/usr/sbin/tmpwatch 336 /usr/local/maldetect/quarantine >> /dev/null 2>&1
/usr/sbin/tmpwatch 336 /usr/local/maldetect/pub/*/ >> /dev/null 2>&1

# check for new release version
# /usr/local/maldetect/maldet -d >> /dev/null 2>&1

# check for new definition set
/usr/local/maldetect/maldet -u >> /dev/null 2>&1

rm -f /tmp/md_scan.txt

	#  Non conventional structures
	if [ -d "/opt/clients" ];then
	        /usr/local/maldetect/maldet -r /opt/clients/ 8 >> /dev/null 2>&1
		/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt
	fi
	if [ -d "/var/aegir" ];then
		/usr/local/maldetect/maldet -r /var/aegir/ 8 >> /dev/null 2>&1
		/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt
	fi

	# MySQL Backups
	if [ -d /opt/backup/mysql/$(date +%Y)/$(date +%m)/$(date +%d) ];then
		/usr/local/maldetect/maldet -r /opt/backup/mysql/$(date +%Y)/$(date +%m)/$(date +%d) 2 >> /dev/null 2>&1
		/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt
	fi

/usr/local/maldetect/maldet -r /var/www/ 8 >> /dev/null 2>&1
/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt

/usr/local/maldetect/maldet -r /home/ 8 >> /dev/null 2>&1
/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt

/usr/local/maldetect/maldet -r /opt/ 8 >> /dev/null 2>&1
/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt

/usr/local/maldetect/maldet -r /tmp/ 8 >> /dev/null 2>&1
/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt

which gluster >>/dev/null 2>&1 && [ -x "$(which gluster 2>&1)" ] && gluster volume info | awk '{ FS = ":" } ; /^Brick[0-9]/ {print $(NF)}' | sort | uniq | while read DIR ; do
    if [ -d "${DIR}" ] ; then
	/usr/local/maldetect/maldet -r "${DIR}" 8 >> /dev/null 2>&1
	/usr/local/maldetect/maldet --report >> /tmp/md_scan.txt
    fi
done

rm -f ${LOCKFILE}
export EDITOR=$BACKUP_EDITOR