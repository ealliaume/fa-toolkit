#!/bin/sh
# @author: Christophe Amory

LINK_DIR=~/fa-git-toolkit
GIT_TOOLKIT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/git
echo $GIT_TOOLKIT_DIR

if [ ! -d $LINK_DIR ]; then
	mkdir -p $LINK_DIR
fi

echo " - Ajout des alias de base"
echo "		* br = branch"
git config --local --unset alias.br
git config --global alias.br 'branch'

echo "		* ci = commit"
git config --local --unset alias.ci
git config --global alias.ci 'commit'

echo "		* co = checkout"
git config --local --unset alias.co
git config --global alias.co 'checkout'

echo "		* st = status"
git config --local --unset alias.st
git config --global alias.st 'status'

echo "		* undo = reset soft HEAD^ (redescend le dernier commit dans le stage)"
git config --local --unset alias.undo
git config --global alias.undo 'reset --soft HEAD^'

echo "		* unstage = reset HEAD -- (annule les dernières modifications non encore commitées)"
git config --local --unset alias.unstage
git config --global alias.unstage 'reset --soft HEAD^'

echo " - Ajout de git missings" 
if [ ! -e $LINK_DIR/git-missings ]; then
	ln -s $GIT_TOOLKIT_DIR/git-missings.sh $LINK_DIR/git-missings
fi
git config --local --unset alias.missings
git config --global alias.missings '!sh '${LINK_DIR}'/git-missings'