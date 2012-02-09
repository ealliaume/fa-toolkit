#!/bin/sh
# @author Christophe Amory
# @author Xavier Bucchiotty
# @author Cédric Pineau
# Remote run

SCRIPTS_DIRECTORY=~/.fa-toolkit
. $SCRIPTS_DIRECTORY/git/safe-push/safe-commons

CURRENT_WORKING_DIR="$(git rev-parse --show-toplevel)"
CURRENT_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"
CURRENT_REVISION="$( git log --pretty=%H -1)"

REMOTE_ALIAS=$(git config branch.$CURRENT_BRANCH.remote)
REMOTE_REPO=$(git config remote.$REMOTE_ALIAS.url)
REMOTE_BRANCH=$(git config branch.$CURRENT_BRANCH.merge)
REMOTE_BRANCH=${REMOTE_BRANCH##refs/heads/}

PRIVATE_BUILD=~/.safe-push
SORTIE_LOG="$PRIVATE_BUILD/sortie.log"

DEFAULT_COMMAND="cd /home/service/remote-run/;";

remoteCommand() {
    COMMAND="${DEFAULT_COMMAND}${1}"
    ssh -T service@$PERSONAL_VM $COMMAND > $SORTIE_LOG
}

if [ -z $PERSONAL_VM ]; then
    logError "La variable \"PERSONAL_VM\" doit être positionnée pour indiquer la VM de remote-run/tests fonctionnels"
    exit 1;
fi

while true ; do
  case "$1" in
    -v|--verbose) 
        SORTIE_LOG=/dev/stdout
        VERBOSE="yes"
    shift ;;
    -d|--dry-run) 
        GIT_DRY_RUN="-n"
    shift ;;
    "") break ;;
    *)
      echo "Paramètre invalide \"$1\""
      echo "Utilisation : remote-safe-push  [-v|--verbose] [-d|--dry-run]"
      exit 1 ;;
  esac
done

if [ ! -d $PRIVATE_BUILD ]; then
    mkdir -p $PRIVATE_BUILD 
else 
    rm -rf $PRIVATE_BUILD/*.log
fi

log "Liste des commits en attente de push"
git log $REMOTE_ALIAS/$REMOTE_BRANCH.. --format='; ;%Cred%h%Creset;%C(yellow)%cd%Creset;%f' --date=iso | column -t -s';'
echo

#### Teste si la branche courante est une 'tracked branch'
log "Vérification de l'existence de la branche sur le repository $REMOTE_ALIAS"
if [ -z $REMOTE_BRANCH ]; then
    logError "Cette branche n'existe pas sur le repository $REMOTE_ALIAS"
fi

log "Détection des modifications (non commitées) en cours..." 
if [ 0 -ne `git status --porcelain | grep -v '??' | wc -l` ]; then
  log "Vous avez des modifications en cours (non commitées), création d'un stash"
  HAS_STASH="yes"
  git stash > $SORTIE_LOG
fi

log "Mise à jour des sources"
git pull --rebase > $SORTIE_LOG

if [ -n "$HAS_STASH" ]; then
  log "Application du stash précédemment créé"
  git stash pop > $SORTIE_LOG
fi

git push remote-run +HEAD:$CURRENT_BRANCH > $SORTIE_LOG
errorHandler "Erreur lors de la mise à jour des sources depuis \"origin\""


#DEBUT DE LA VALIDATION
log "Lancement de la compilation, TU et TI"
remoteCommand "git clean -df; git checkout -f ${CURRENT_BRANCH}"
remoteCommand "mvn clean install"
errorHandler "Erreur lors de la compilation, TU ou TI"

log "Lancement du JBOSS"
remoteCommand "sh ~/service.sh stop"  > $SORTIE_LOG 2>&1
sleep 5
ssh service@$PERSONAL_VM 'rm -rf /home/service/jboss-4.0.5.GA/server/insito/tmp/*;rm -rf /home/service/jboss-4.0.5.GA/server/insito/work/*;' > $SORTIE_LOG
ssh service@$PERSONAL_VM '/home/service/jboss-4.0.5.GA/bin/run.sh -c insito ' > $SORTIE_LOG &
errorHandler "Erreur lors du démarrage de JBOSS"

sleep 30

log "Lancement des TFs"
remoteCommand "mvn clean install -PoldTestsFonctionnels -Dtest=com.financeactive.insito.RunAllTests" > $SORTIE_LOG
if [ $? -ne 0 ]; then
    if [ -z "$VERBOSE" ]; then
        tail -50 $SORTIE_LOG     
    fi
    remoteCommand "sh ~/service.sh stop" > $SORTIE_LOG 2>&1
    logError "Erreur lors des tests fonctionnels"
fi

remoteCommand "sh ~/service.sh stop" > $SORTIE_LOG 2>&1

log "Mise à jour du repository $REMOTE_ALIAS: $REMOTE_REPO $REMOTE_BRANCH"
git push $GIT_DRY_RUN $REMOTE_REPO $CURRENT_REVISION:$REMOTE_BRANCH

echo
log "Terminé avec succès :)"
echo
