#!/bin/sh
# @author Christophe Amory
# @author Xavier Bucchiotty
# @author Cédric Pineau
# Remote run

SCRIPTS_DIRECTORY=`dirname $0`
. $SCRIPTS_DIRECTORY/safe-commons

CURRENT_WORKING_DIR="$(git rev-parse --show-toplevel)"
CURRENT_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

REMOTE_ALIAS=$(git config branch.$CURRENT_BRANCH.remote)
REMOTE_REPO=$(git config remote.$REMOTE_ALIAS.url)
REMOTE_BRANCH=$(git config branch.$CURRENT_BRANCH.merge)
REMOTE_BRANCH=${REMOTE_BRANCH##refs/heads/}

PRIVATE_BUILD="${CURRENT_WORKING_DIR}/../clone/${CURRENT_WORKING_DIR##*/}"
PRIVATE_BUILD_LOG="${PRIVATE_BUILD}_log"
SORTIE_LOG=$PRIVATE_BUILD_LOG/sortie.log

if [ -z $PERSONAL_VM ]; then
  logError "La variable \"PERSONAL_VM\" doit être positionnée pour indiquer la VM de remote-run/tests fonctionnels"
fi

while true ; do
  case "$1" in
    -r|--remote)
        REMOTE="yes"
    shift ;;
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
      echo "Utilisation : safe-push [-r|--remote] [-v|--verbose] [-d|--dry-run]"
      exit 1 ;;
  esac
done


if [ -z "$VERBOSE" ]; then
  rm -rf $PRIVATE_BUILD_LOG/*.log
  mkdir -p $PRIVATE_BUILD $PRIVATE_BUILD_LOG 
fi

log "Liste des commits en attente de push"
git log $REMOTE_ALIAS/$REMOTE_BRANCH.. --format='; ;%Cred%h%Creset;%C(yellow)%cd%Creset;%f' --date=iso | column -t -s';'
echo

#### Teste si la branche courante est une 'tracked branch'
log "Vérification de l'existence de la branche sur le repository $REMOTE_ALIAS"
if [ 0 -eq `git ls-remote $REMOTE_ALIAS refs/heads/$REMOTE_BRANCH | grep -c "$REMOTE_BRANCH"` ]; then
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
errorHandler "Erreur lors de la mise à jour des sources depuis $REMOTE_ALIAS"

if [ -n "$HAS_STASH" ]; then
  log "Application du stash précédemment créé"
  git stash pop > $SORTIE_LOG
fi


### Créer le clone du dépot local s'il n'existe pas
if [ ! -d "$PRIVATE_BUILD" ]; then
  log "Création du clone : $PRIVATE_BUILD"
  git clone . "$PRIVATE_BUILD"
fi


### Détermine la branche courante du clone
cd $PRIVATE_BUILD
CLONE_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

### Charge dans le clone la branche de travail courante ou la créer si elle n'existe pas.
if [ "$CURRENT_BRANCH" != "$CLONE_BRANCH" ]; then
  if [ 0 -eq `git branch | grep -c "$CURRENT_BRANCH"` ]; then
    log "La branche n'est pas présente dans le clone. Création de la branche."
    git fetch > $PRIVATE_BUILD_LOG/checkout_branch.log
    git checkout $REMOTE_ALIAS/$CURRENT_BRANCH -b $CURRENT_BRANCH > $SORTIE_LOG
    errorHandler "Erreur lors de la création de la branch"
  else  
    log "checkout de la branche pour le clone"
    git checkout $CURRENT_BRANCH > $SORTIE_LOG
    errorHandler "Erreur lors du changement de branche"
  fi
fi

log "Nettoyage du clone"
git clean -df >$SORTIE_LOG
log "Mise à jour du clone"
git pull --rebase > $SORTIE_LOG

EXECUTION_PLACE=$PRIVATE_BUILD
COMMAND="sh -c"
scp $SCRIPTS_DIRECTORY/safe-commons "$PRIVATE_BUILD"
scp $SCRIPTS_DIRECTORY/insito-push-validator.sh "$PRIVATE_BUILD/validator.sh" #TODO : détecter quel validateur utiliser
if [ -n "$REMOTE" ]; then
  log "Upload sur " $PERSONAL_VM
  EXECUTION_PLACE="/home/service/remote-run/"
  rsync -az --delete $PRIVATE_BUILD/* service@"$PERSONAL_VM":"$EXECUTION_PLACE"
  COMMAND="ssh service@$PERSONAL_VM source ~/.profile ; cd $EXECUTION_PLACE ; sh "
fi

log "Validation.."
$COMMAND $EXECUTION_PLACE/validator.sh $PERSONAL_VM > $SORTIE_LOG
errorHandler "Erreur lors de la validation"

log "Mise à jour du repository $REMOTE_ALIAS: $REMOTE_REPO $CURRENT_BRANCH"
git push $GIT_DRY_RUN $REMOTE_REPO $CURRENT_BRANCH:$REMOTE_BRANCH

cd $CURRENT_WORKING_DIR > /dev/null
git pull

echo
log "Terminé avec succès :)"
echo


