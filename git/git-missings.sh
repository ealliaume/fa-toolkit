#!/bin/sh
# @author: Christophe Amory

# Affiche les différences de commits entre deux branches.
# Utilisation: git missings                   --> affiche les commits absents entre la branche en cours et la branche distante associée. Indique donc les commits non encore poussé vers le dépôt distant.
#	       	   git missings branche1          --> affiche les commits absents entre la branche en cours et le branche 'branche1'	
#              git missings branche1 branche2 --> affiche les commits absents entre 'branche1' et 'branch2'
#
# git missings,  git missings origin/master,  git master origin/master sont équivalents si la branch master est la branche en cours et qu'elle est associée à la branche distante master du dépôt origin

if [ $# -eq 1 ] && [ $1=="-h" ]; then
   echo "Affiche les différences de commits entre deux branches."
   echo "git missings                   --> affiche les commits absents entre la branche en cours et la branche distante associée. Indique donc les commits non encore poussé vers le dépôt distant."
   echo "git missings branche1          --> affiche les commits absents entre la branche en cours et le branche 'branche1'"
   echo "git missings branche1 branche2 --> affiche les commits absents entre 'branche1' et 'branch2'"
   echo "git missings,  git missings origin/master,  git master origin/master sont équivalents si la branch master est la branche en cours et qu'elle est associée à la branche distante master du dépôt origin"
   exit
fi

BRANCH_START="$(git rev-parse --symbolic --abbrev-ref $(git symbolic-ref HEAD))"

if [ $# -eq 0 ]; then
   REMOTE=$(git config "branch.${BRANCH_START}.remote") || (echo "Il n'y a pas de branche distante associée à $BRANCH_START";exit)
   REMOTE_BRANCH=$(git config branch.$BRANCH_START.merge) || ( echo "Il n'y a pas de branche distante associée à $BRANCH_START";exit)
   BRANCH_END="$REMOTE/${REMOTE_BRANCH##refs/heads/}"
fi

if [ $# -eq 1 ]; then
   BRANCH_END=$1
fi

if [ $# -eq 2 ]; then
   BRANCH_START=$1
   BRANCH_END=$2
fi

echo "$BRANCH_START < > $BRANCH_END"
git log --left-right --color-words  --graph --cherry-pick --decorate --pretty=format:'%Cred%h%Creset %C(yellow)[%an]%Creset %s' --abbrev-commit --boundary $BRANCH_START...$BRANCH_END
