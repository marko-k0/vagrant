#!/usr/local/bin/bash
#
# Copyright (C) 2015 Marko Kosmerl (marko.kosmerl@gmail.com).
# 
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation; version 2 of the License. 
# 
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License 
# along with this program or from the site that you downloaded it 
# from; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA.
# 
# This script provides a regular backup using zfsnap and zxfer.
#

#
# Prerequisites:
# - bash (backup server)
# - xzxfer (backup server),
# - zfsnap (backup and remote server),
# - ssh pub-key auth (to remote server) for $SSH_USER.
#	

which zxfer > /dev/null || ( echo "zxfer missing! \n" && exit )
which zfsnap > /dev/null || ( echo "zfsnap missing! \n" && exit )
 
SSH_USER=backup
LOGDIR=/var/log/backup
PIDFILE=/var/run/backup-zxfer.pid
 
while getopts :c:r:vd opt; do
  case $opt in
    c)
      CONFIG=$OPTARG
      ;;
    d)
      DRYRUN=1
      ;;
    r)
      RESTORE=$OPTARG
      ;;
    v)
      VERBOSE=1
      ;;
    h)
      print_help
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit
      ;;
  esac
done

validate() {
	[ -z "$CONFIG" ] && [ -z "$RESTORE" ] && PRINT_HELP=0
	[ -n "$CONFIG" ] && [ -n "$RESTORE" ] && PRINT_HELP=0

	if [ -n "$PRINT_HELP" ]
	then
		print_help
		exit
	fi

	if [ -f $PIDFILE ];
	then
		ps -p `cat $PIDFILE` > /dev/null
		if [ $? -eq 0 ]; then
			echo "$0 is already running."
			exit
		fi
		rm $PIDFILE
	fi
	
	mkdir -p $LOGDIR
}

main() {
	validate

	echo "[$(date)] ########### BACKUP START " >> $LOGDIR/general.log
	START=$(date +%s)

	echo $$ > $PIDFILE
	if [ -n "$RESTORE" ]
	then
		restore
	elif [ -n "$CONFIG" ]
	then
		backup
	fi
	rm $PIDFILE

	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "[$(date)] ########## BACKUP END (runtime: $DIFF seconds)" >> $LOGDIR/general.log
	echo $DIFF > $LOGDIR/general.time
}

backup() {
	readarray CONFIG_ARRAY < $CONFIG
	for line in "${CONFIG_ARRAY[@]}"
	do
		IFS=':' read -a CONFIG_LINE <<< "$line"

		S=$(date +%s)
		echo "[$(date)] ###### Making backup on ${CONFIG_LINE[0]}" >> $LOGDIR/general.log

		run_zxfer_backup ${CONFIG_LINE[0]} ${CONFIG_LINE[1]} ${CONFIG_LINE[2]}
		run_zfsnap_destroy ${CONFIG_LINE[0]} ${CONFIG_LINE[1]} ${CONFIG_LINE[2]}

		E=$(date +%s)
		D=$(( $E - $S ))
		echo "[$(date)] ###### Backup finished on ${CONFIG_LINE[0]} (runtime: $D seconds)" >> $LOGDIR/general.log
		echo $D > $LOGDIR/${CONFIG_LINE[0]}.time
	done
}

run_zxfer_backup() {
	DATASET=$3/$1
	run_create_local_datasets $1 $2 $3
	run_cmd $1 "zxfer -v -F -R $2 -O '$SSH_USER@$1 -q sudo' $DATASET"
}

run_create_local_datasets() {
	if [[ $2 == *"/" ]]; 
	then
		DATASET=${2:0:-1}
		SUBSETS=$(ssh $SSH_USER@$1 -q "zfs list -t filesystem -H -r -d 1 $DATASET | grep $2 | cut -f 1" 2>&1)
		if [[ $SUBSETS == "dataset does not exist" ]];
		then
			echo "dataset $DATASET does not exist >> $LOGDIR/${1}.log"	
		else
			for dataset in $SUBSETS; do run_cmd $1 "zfs list $dataset > /dev/null 2>&1 || zfs create $dataset"; done
		fi
	else
		run_cmd $1 "zfs list $3/$1 > /dev/null 2>&1 || zfs create $3/$1"
	fi
}

run_zfsnap_destroy() {
	run_cmd $1 "zfsnap destroy -rv $DATASET"
}

restore() {
	IFS=':' read -a CONFIG_LINE <<< "$RESTORE"
	run_zfs_restore ${CONFIG_LINE[0]} ${CONFIG_LINE[1]} ${CONFIG_LINE[2]}
}

run_zfs_restore() {
	HOST=$1
	SNAPSHOT=$2
	ORIGINAL_DS=$3
	RESTORE_DS=${3}_restore
	BACKUP_DS=${3}_backup-$(date +%s)

	RESTORE_EXISTS=$(ssh $SSH_USER@$HOST -q "sudo zfs list -H $RESTORE_DS | grep $RESTORE_DS")
	if [ -z "$RESTORE_EXISTS" ]
	then	
		run_cmd $1 "zfs send $SNAPSHOT | ssh $SSH_USER@$HOST -q sudo zfs recv -F $RESTORE_DS"
	fi

	OPENED_FDS=$(ssh $SSH_USER@$1 -q "sudo fstat /$ORIGINAL_DS | grep $ORIGINAL_DS")
	if [ -n "$OPENED_FDS" ]
	then
		echo "Opened file descriptors inside ${ORIGINAL_DS}. Take care of that and run again."
	else
		RESTORE_TIME=$(echo $SNAPSHOT | cut -d '@' -f 2)

		run_ssh_cmd $HOST "zfs rename $ORIGINAL_DS $BACKUP_DS"
		run_ssh_cmd $HOST "zfs rename $RESTORE_DS $ORIGINAL_DS"
		run_ssh_cmd $HOST "zfs rollback $ORIGINAL_DS@$RESTORE_TIME"

		test -z "$DRYRUN" && echo "Manually delete ${BACKUP_DS} dataset."
	fi
}

run_cmd() {
	if [ -n "$DRYRUN" ];
	then
		echo "$2"
	else
		test -n "$VERBOSE" && echo "[$(date)] $2" >> $LOGDIR/${1}.log
		test -n "$RESTORE" && echo "$2"
		echo "$2" | sh >> $LOGDIR/${1}.log 2>&1
	fi
}

run_ssh_cmd() {
	if [ -n "$DRYRUN" ];
	then
		echo "ssh $SSH_USER@$1 -q \"echo '$2' | sudo sh\" >> $LOGDIR/${1}.log 2>&1"
	else
		test -n "$VERBOSE" && echo "[$(date)] ssh $SSH_USER@$1 -q \"echo '$2' | sudo sh\" >> $LOGDIR/${1}.log 2>&1" >> $LOGDIR/${1}.log
		test -n "$RESTORE" && echo "ssh $SSH_USER@$1 -q \"echo '$2' | sudo sh\""
		ssh $SSH_USER@$1 -q "echo '$2' | sudo sh" >> $LOGDIR/${1}.log 2>&1
	fi
}

print_help() {
echo -e \
"
 $0 -h
 $0 -c <conf-file> -d -v
 $0 -r <host>:<snapshot>:<dataset> -d -v

  -h help
  -c backup mode
  -r restore mode
  -d dry mode
  -v verbose mode
"
}

main
