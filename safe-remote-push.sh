#!/bin/sh
# @author Christophe Amory
# @author Xavier Bucchiotty
# @author Cédric Pineau
# Remote run

CURRENT_WORKING_DIR="$(git rev-parse --show-toplevel)"
PRIVATE_BUILD="${CURRENT_WORKING_DIR}/../clone/${CURRENT_WORKING_DIR##*/}"
PRIVATE_BUILD_LOG="${PRIVATE_BUILD}_log"
CURRENT_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"
SCRIPTS_DIRECTORY=`dirname $0`

SORTIE_LOG=$PRIVATE_BUILD_LOG/sortie.log

if [ 1 -eq $# ]  && [  "--verbose" = $1 ]; then
  SORTIE_LOG=/dev/stdout
fi

#### Teste si la branche courante est une 'tracked branch'
echo "* Vérification de l'existence de la branche sur le repository \"origin\""
if [ 0 -eq `git ls-remote origin refs/heads/$CURRENT_BRANCH | grep -c "$CURRENT_BRANCH"` ]; then
  echo "Cette branche n'existe pas sur le repository \"origin\""
  exit 1
fi

### Détermine le dépot distant
if [ 0 -eq `git remote -v | grep -c push` ]; then
  REMOTE_REPO=`git remote -v | sed 's/origin//'`
else
  REMOTE_REPO=`git remote -v | grep "(push)" | sed 's/origin//' | sed 's/(push)//'`
fi


### Créer le clone du dépot local s'il n'existe pas sinon nettoie le dossier de log
if [ ! -d "$PRIVATE_BUILD" ]; then
  echo "* Création du clone : $PRIVATE_BUILD"
  git clone . "$PRIVATE_BUILD"
  echo "* Création du répertoire de log: $PRIVATE_BUILD_LOG"
  mkdir $PRIVATE_BUILD_LOG
else
  echo "* Nettoyage des fichiers de logs"
  rm -rf $PRIVATE_BUILD_LOG/*.log
fi

echo "* Détection des modifications (non commitées) en cours..." 
if [ 0 -ne `git status --porcelain | grep -c ' ' ` ]; then
  echo "* Vous avez des  modifications en cours (non commitées), création d'un stash"
  NEED_STASH="1"
  git stash > $SORTIE_LOG
fi

echo "* Mise à jour des sources"
git pull --rebase > $SORTIE_LOG
if [ $? -ne 0 ]; then
  if [ "$NEED_STASH" = "1" ]; then
    echo "* Ré-application du stash précédemment créé"
    git stash pop > $SORTIE_LOG
  fi


  echo ; echo
  tail -50 $PRIVATE_BUILD_LOG/sortie.log
  echo ">>>> Erreur lors de la mise à jours des sources :("
  exit
fi

if [ "$NEED_STASH" = "1" ]; then
  echo "* Ré-application du stash précédemment créé"
  git stash pop > $SORTIE_LOG
fi

### Détermine la branche courante du clone"
cd $PRIVATE_BUILD
CLONE_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

### Change la branche du clone avec celle correspondant à celle du dépot local ou la créer si elle n'existe pas.
if [ "$CURRENT_BRANCH" != "$CLONE_BRANCH" ]; then
  if [ 0 -eq `git branch | grep -c "$CURRENT_BRANCH"` ]; then
    echo "* La branche n'est pas présente dans le clone. Création de la branche."
    git fetch > $PRIVATE_BUILD_LOG/checkout_branch.log
    git checkout origin/$CURRENT_BRANCH -b $CURRENT_BRANCH > $SORTIE_LOG
    if [ $? -ne 0 ]; then
      echo ; echo
      tail -50 $PRIVATE_BUILD_LOG/sortie.log
      echo ">>>> Erreur lors de la création de la branche :(" 
      exit 1
    fi
  else  
    echo "* checkout de la branche pour le clone"
    git checkout $CURRENT_BRANCH > $SORTIE_LOG
    if [ $? -ne 0 ]; then
      echo ; echo
      tail -50 $PRIVATE_BUILD_LOG/sortie.log
      echo ">>>> Erreur lors du changement de branche :("
      exit 1
    fi
  fi
fi

echo "* Nettoyage du clone"
git clean -df >$SORTIE_LOG

echo "* Mise à jour du clone"
git pull --rebase > $SORTIE_LOG


PLACE="local"
EXECUTION_PLACE=$PRIVATE_BUILD
COMMAND="sh -c"
scp $SCRIPTS_DIRECTORY/insito-push-validator.sh "$PRIVATE_BUILD/validator.sh" #TODO : détecter quel validateur utiliser

if [ 1 -eq $# ]  && [  "--remote" = $1 ]; then
  echo ""
  PLACE="remote"
  EXECUTION_PLACE="/home/service/sc-remote-run/"
  rsync -az --delete $PRIVATE_BUILD/* service@hudson:$EXECUTION_PLACE
  COMMAND="ssh service@hudson source ~/.profile ; cd $EXECUTION_PLACE ; sh "
fi

echo
echo "* Validation du push depuis le clone" $PLACE
$COMMAND $EXECUTION_PLACE/validator.sh > $SORTIE_LOG
if [ $? -ne 0 ]; then
  tail -50 $SORTIE_LOG
  exit 1
fi

echo
echo "* Mise à jour du repository distant : $REMOTE_REPO $CURRENT_BRANCH"
git push  $REMOTE_REPO $CURRENT_BRANCH

git pull

echo
echo "Terminé avec succès :)"
echo


