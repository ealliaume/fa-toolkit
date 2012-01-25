#!/bin/bash
# @author Christophe Amory
# @author Xavier Bucchiotty
# Local run

CURRENT_WORKING_DIR="$(git rev-parse --show-toplevel)"
PRIVATE_BUILD="${CURRENT_WORKING_DIR}/../clone/${CURRENT_WORKING_DIR##*/}"
PRIVATE_BUILD_LOG="${PRIVATE_BUILD}_log"
INIT_DIR=`pwd`
CURRENT_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

SORTIE_LOG=$PRIVATE_BUILD_LOG/sortie.log
VERBOSE=0

if  [ $# -ge 1 ] && [ "--verbose" = $1 ]; then
  SORTIE_LOG=/dev/stdout
  VERBOSE=1
fi

if [ $# -ge 2 ] &&  [ "--verbose" = $2 ]; then
  SORTIE_LOG=/dev/stdout
  VERBOSE=1
fi


##Fonction de log
#@param 1 message à logger
function log() {
	echo "\033[0;32m* $1\033[0m"
}

##Fonction de gestion des messages d'erreur
#@param 1 message d'erreur
function errorHandler() {
if [ $? -ne 0 ]; then
      echo ; echo
      if [ $VERBOSE -eq 0 ]; then
	      tail -50 $SORTIE_LOG     
      fi
      echo "\033[1;31m>>>>ERROR : $1\033[0m" 
      cd $INIT_DIR > /dev/null
      exit
fi
}




#### Test si la branche courante est une 'tracked branch'
log "Vérification de l'existence de la branche sur Github" 
if [ 0 -eq `git ls-remote origin refs/heads/$CURRENT_BRANCH | grep -c "$CURRENT_BRANCH"` ]; then
log "Cette branche n'existe pas sur GitHub"
 exit
fi

### Détermine le dépot distant
if [ 0 -eq `git remote -v | grep -c push` ]; then
  REMOTE_REPO=`git remote -v | sed 's/origin//'`
else
  REMOTE_REPO=`git remote -v | grep "(push)" | sed 's/origin//' | sed 's/(push)//'`
fi

### Créer le clone du dépot local s'il n'existe pas sinon nettoie le dossier de log
if [ ! -d "$PRIVATE_BUILD" ]; then
  log "Création du clone : $PRIVATE_BUILD"
  git clone . "$PRIVATE_BUILD"
  log "Création du répertoire de log: $PRIVATE_BUILD_LOG"
  mkdir $PRIVATE_BUILD_LOG
else
  log "Nettoyage des fichiers de logs"
  rm -rf $PRIVATE_BUILD_LOG/*.log
fi

log "Détection des stashs en cours..." 
if [ 0 -ne `git status --porcelain | grep -c ' ' ` ]; then
  log "Vous avez des modifications en cours, on fait un stash"
  NEED_STASH="1"
  git stash > $SORTIE_LOG
fi

log "Mise à jours des sources"
git pull --rebase > $SORTIE_LOG
if [ $? -ne 0 ]; then
  if [ "$NEED_STASH" = "1" ]; then
    log "Application du stash fait précédemment"
    git stash pop > $SORTIE_LOG
  fi
  errorHandler "Erreur lors de la mise à jours des sources :("
fi

if [ "$NEED_STASH" = "1" ]; then
  log "Application du stash fait précédemment"
  git stash pop > $SORTIE_LOG
fi

### Détermine la branche courante du clone"
cd $PRIVATE_BUILD
CLONE_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

### Change la branche du clone avec celle correspondant à celle du dépot local ou la créer si elle n'existe pas.
if [ "$CURRENT_BRANCH" != "$CLONE_BRANCH" ]; then
  if [ 0 -eq `git branch | grep -c "$CURRENT_BRANCH"` ]; then
    log "La branche n'est pas présente dans le clone. Création de la branche."
    git fetch > $PRIVATE_BUILD_LOG/checkout_branch.log
    git checkout origin/$CURRENT_BRANCH -b $CURRENT_BRANCH > $SORTIE_LOG
    errorHandler "Erreur lors de la création de la branch :("
  else  
    log "checkout de la branche pour le clone"
    git checkout $CURRENT_BRANCH > $SORTIE_LOG
    errorHandler "Erreur lors du changement de branche :("
  fi
fi

log "Nettoyage du clone"
git clean -df >$SORTIE_LOG

log "Mise à jour du clone"
git pull --rebase > $SORTIE_LOG

log "Compilation du projet depuis le clone"
/opt/local/bin/mvn clean install -Dmaven.test.skip > $SORTIE_LOG
errorHandler "Erreur de compilation :("

log "Exécution des tests depuis le clone"
/opt/local/bin/mvn integration-test > $SORTIE_LOG
errorHandler "Erreur lors de l'exécution des test :("


log "Construction du ZIP pour envoi sur VM"
/opt/local/bin/mvn package -Dmaven.test.skip -PpackageEarData  > $SORTIE_LOG
errorHandler "Erreur de la génération du zip"

log "Deploiement de l'application sur un vm de test"
#Renommage du zip comme attendu par le script de redéploiement sur la vm
mv ear/ear/target/earData.zip ear/ear/target/consoleUploadedFile

log "Upload du zip"
scp ear/ear/target/consoleUploadedFile service@$PERSONAL_VM:/home/service/> $SORTIE_LOG
errorHandler "Erreur lors du déploiement de l'ear sur $PERSONAL_VM"

log "Redémarrage du JBOSS sur $PERSONAL_VM"
ssh service@$PERSONAL_VM "/home/service/service.sh refresh" > $SORTIE_LOG
errorHandler "Erreur lors du démarrage de JBOSS"

log "Application deployée, lancement des tests fonctionnels"
mvn test -PoldTestsFonctionnels -Dtest=com.financeactive.insito.RunAllTests
if [ $? -ne 0 ]; then
 echo ; echo
 ssh service@$PERSONAL_VM "/home/service/service.sh stop" > $SORTIE_LOG
 if [ 0 -eq $VERBOSE ];then
	 tail -50 $PRIVATE_BUILD_LOG/sortie.log
  if;
  echo ">>>>ERROR: Erreur lors des tests fonctionnels"
  cd $INIT_DIR > /dev/null
  exit
fi

log "Tests fonctionnels OK, stop de l'instance JBOSS"
ssh service@$PERSONAL_VM "/home/service/service.sh stop" > $SORTIE_LOG

log "Mise à jour du répo. distant : $REMOTE_REPO $CURRENT_BRANCH"

if [ $# -ge 1 ] &&  [ "--dry-run" = $1 ]; then
	git push -n $REMOTE_REPO $CURRENT_BRANCH
else if [ $# -ge 2 ] &&  [ "--dry-run" = $2 ]; then
		git push -n $REMOTE_REPO $CURRENT_BRANCH
	else
		git push $REMOTE_REPO $CURRENT_BRANCH
	fi
fi


cd $INIT_DIR  > /dev/null

git pull

echo
log "Terminé avec succès :)"
echo


