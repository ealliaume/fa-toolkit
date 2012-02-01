#!/bin/sh
# @author: Christophe Amory

LINK_DIR="$HOME/.fa-toolkit"
TOOLKIT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $TOOLKIT_DIR

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

if [ ! -d $LINK_DIR ]; then
	ln -s $TOOLKIT_DIR $LINK_DIR
fi
echo " - Ajout de git missings" 
git config --local --unset alias.missings
git config --global alias.missings '!sh '${LINK_DIR}'/git/git-missings.sh'