#!/bin/sh
# @author Christophe Amory
# @author Xavier Bucchiotty
# @author Cédric Pineau
# Remote run

SCRIPTS_DIRECTORY=~/.fa-toolkit
. $SCRIPTS_DIRECTORY/git/safe-push/safe-commons

if [ $# -eq 0 ]; then
	logError "Il faut passer en paramètre du script le nom de votre VM"
fi

if [ ! -d ./.git ]; then
	logError "Le script doit être lancé depuis le répertoire principal de votre projet git"
fi

log "Upload de votre clé sur votre VM"
sh $SCRIPTS_DIRECTORY/ssh/ssh-deploy-pubkey.sh service@$1
errorHandler "ERREUR LORS DE L'UPLOAD DE VOTRE CLE"

if [ -f ~/.bashrc  ]; then
	if [ 0 -eq ` grep PERSONAL_VM ~/.bash_profile | wc -l` ]; then
        log "Ajout de la variable d'environnement dans .bash_profile"
       	echo "export PERSONAL_VM=$1" >> ~/.bash_profile
       	echo "alias vm=\"ssh service@$1\"" >> ~/.bash_aliases
	fi
elif [ 0 -eq ` grep PERSONAL_VM ~/.profile | wc -l` ]; then
	log "Ajout de la variable d'environnement dans .profile"
	echo "export PERSONAL_VM=$1" >> ~/.profile
	echo "alias vm=\"ssh service@$1\"" >> ~/.profile
else
	log "Vous avez déjà initialisé votre PERSONAL_VM"
fi

log "Test de connexion à la VM: ssh service@$1"
ssh service@$1 echo "Connexion OK"

log "Ajout du remote \"remote-run\" dans git"
git remote rm remote-run 
git remote add remote-run service@$1:/home/service/remote-run

log "Initialisation du repo distant"
git push remote-run +master:master

log "Test de compilation sur le repo distant"
ssh service@$1 "cd ~/remote-run/; git checkout -f; mvn install -Dmaven.test.skip"

echo
log "Installation OK"
