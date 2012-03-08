#!/bin/bash
# This script initializes symbolic links to Insito clone inside JBoss.
# It can be run multiple times.
# @author Olivier Le Merdy <olemerdy@financeactive.com>

# @param $1 target dir to check for existence
function checkDirExist {
	if [ ! -d $1 ]; then
		echo "Directory $1 does not exist"
		exit 1
	fi
}

# @param $1 target to get rid of (backed up if file, wiped out otherwise)
function getRidOf {
	if [ -L $1 ]; then
		echo "Removing existing symbolic link: $1"
		rm $1
	elif [ -f $1 ]; then
		BACKUP_DIR="/tmp/insito-jbossconf"
		if [ ! -e $BACKUP_DIR ]; then
			echo "Creating backup directory: $BACKUP_DIR"
			mkdir -p $BACKUP_DIR
		fi
		BACKUP_FILE=$BACKUP_DIR`basename $1`.bak
		echo "Creating backup file: $1 -> $BACKUP_FILE"
		mv $1 $BACKUP_FILE
	elif [ -e $1 ]; then
		echo "Wiping out: $1"
		rm -rf $1
	fi
}

# @param $1 linked file name
# @param $2 source directory
# @param $3 target directory
# @param $4 target file name (optional)
function link2conf {
	checkDirExist $3
	getRidOf "$3/$1"
	if [ $4 ]; then
		targetFileName=$4
	else
		targetFileName=$1
	fi
	echo "Linking conf file \"$2/$1\" -> \"$3/$targetFileName\""
	ln -s "$2/$1" "$3/$targetFileName"
}

# @param $1 linked file name
# @param $2 source directory
# @param $3 target directory
function link2checkedconf {
	if [ -e "$2/$1" ]; then 
		link2conf $1 $2 $3
	else
		echo "Configuration file \"$2/$1\" not found, skipping"
	fi
}

# Usage

echo -e "Usage: $0 [<Insito dir> [<JBoss Home>]]\n"

# INSITO_HOME

if [ ! -z $1 ]; then
	INSITO_HOME=$1
	echo "\$INSITO_HOME explicitly set to: $INSITO_HOME"
else
	INSITO_HOME="$HOME/Documents/developpement/Projets/insito"
	echo "\$INSITO_HOME defaulting to: $INSITO_HOME"
fi

checkDirExist $INSITO_HOME

# CONF_HOME

CONF_HOME="$INSITO_HOME/data/conf/$USER"
echo "\$CONF_HOME set to: $CONF_HOME"

checkDirExist $CONF_HOME

# JBOSS_HOME

if [ ! -z $2 ]; then
	JBOSS_HOME=$2
	echo "\$JBOSS_HOME explicitly set to: $JBOSS_HOME"
elif [ -z $JBOSS_HOME ]; then
	JBOSS_DIR=`ls $HOME/Documents/developpement/ | grep jboss | tail -n 1`
	if [ ! -d $JBOSS_DIR ]; then
		echo "Unable to find a suitable JBOSS_HOME automatically"
		exit 1
	else
		JBOSS_HOME="$HOME/Documents/developpement/$JBOSS_DIR"
		echo "\$JBOSS_HOME defaulting to: $JBOSS_HOME"
	fi
else
	echo "\$JBOSS_HOME defaulting to environment variable: $JBOSS_HOME"
fi

checkDirExist $JBOSS_HOME

echo -e "\nConfiguration is OK\n"

# Delete existing .ear files in JBoss deploy dir
echo "Removing existing EARs in \"$JBOSS_HOME/server/insito/deploy\""
rm -f $JBOSS_HOME/server/insito/deploy/*.ear
echo -e "Cleaning up temporary dirs \"$JBOSS_HOME/server/insito/tmp\" and \"$JBOSS_HOME/server/insito/work\"\n"
rm -rf $JBOSS_HOME/server/insito/tmp/* $JBOSS_HOME/server/insito/work

# insito-ds.xml
link2checkedconf insito-ds.xml $CONF_HOME $JBOSS_HOME/server/insito/deploy

# log4j.xml
link2checkedconf log4j.xml $CONF_HOME $JBOSS_HOME/server/insito/conf

# properties-service.xml
link2checkedconf properties-service.xml $CONF_HOME $JBOSS_HOME/server/insito/deploy

# quartz.properties
link2checkedconf quartz.properties $CONF_HOME $JBOSS_HOME/server/insito/conf

# run.conf
link2checkedconf run.conf $CONF_HOME $JBOSS_HOME/bin

# finactive-ear.ear
link2conf finactive-ear.ear $INSITO_HOME/ear/ear/target $JBOSS_HOME/server/insito/deploy finactive-ear.old.ear
link2conf finactive-ear.ear $INSITO_HOME/ear/target $JBOSS_HOME/server/insito/deploy
