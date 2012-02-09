#!/bin/sh
# @author: Christophe Amory

# Affiche les différences de commits entre deux branches.
# Utilisation: git missings                   --> affiche les commits absents entre la branche en cours et la branche distante associée. Indique donc les commits non encore poussé vers le dépôt distant.
#	       	   git missings branche1          --> affiche les commits absents entre la branche en cours et le branche 'branche1'	
#              git missings branche1 branche2 --> affiche les commits absents entre 'branche1' et 'branch2'
#
# git missings,  git missings origin/master,  git master origin/master sont équivalents si la branch master est la branche en cours et qu'elle est associée à la branche distante master du dépôt origin

if [ $# -eq 1 ] && [ "$1" = "-h" ]; then
   echo "Affiche les différences de commits entre deux branches."
   echo "git missings"
   echo "   --> affiche la différence de commits entre la branche en cours et la branche distante associée." 
   echo "       Indique donc les commits non encore poussé vers le dépôt distant."
   echo
   echo "git missings branche1"
   echo "   --> affiche les commits absents entre la branche en cours et le branche 'branche1'"
   echo
   echo "git missings branche1 branche2"
   echo "   --> affiche les commits absents entre 'branche1' et 'branch2'"
   echo
   echo "git missings,  git missings origin/master,  git master origin/master"
   echo "   sont équivalents si la branche master est la branche en cours et" 
   echo "   qu'elle est associée à la branche distante master du dépôt origin"
   exit
fi

CURRENT_BRANCH="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

if [ $# -eq 0 ]; then
   REMOTE=$(git config branch.${CURRENT_BRANCH}.remote)
   if [ -z "$REMOTE" ]; then
      echo "Il n'y a pas de branche distante associée à $CURRENT_BRANCH";
   	  exit 1;
   fi

   REMOTE_BRANCH=$(git config branch.$CURRENT_BRANCH.merge)
   if [ -z "$REMOTE_BRANCH" ]; then
      echo "Il n'y a pas de branche distante associée à $CURRENT_BRANCH";
   	  exit 1;
   fi
   BRANCH_START=$REMOTE/${REMOTE_BRANCH##refs/heads/}
   BRANCH_END=$CURRENT_BRANCH
fi

if [ $# -eq 1 ]; then
   BRANCH_START=$1
   BRANCH_END=$CURRENT_BRANCH
fi

if [ $# -eq 2 ]; then
   BRANCH_START=$1
   BRANCH_END=$2
fi

echo "$BRANCH_START< > $BRANCH_END"
git log --left-right --color-words  --graph --cherry-pick --decorate --pretty=format:'%Cred%h%Creset %C(yellow)[%an]%Creset %s' --abbrev-commit --boundary $BRANCH_START...$BRANCH_END
