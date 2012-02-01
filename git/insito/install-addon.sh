#!/bin/sh
LINK_DIR="$HOME/.fa-toolkit"

echo "Configuration du pull en rebase"
git config --local branch.patch.rebase true
git config --local branch.master.rebase true

git config --local alias.safe-push '!sh '${LINK_DIR}'/git/safe-push/safe-push.sh'
git config --local alias.remote-safe-push '!sh '${LINK_DIR}'/git/insito/remote-safe-push.sh'

if [ 1 -eq $# ]; then
    $LINK_DIR/git/safe-push/install-remote-run-poste.sh $1
else
    echo "Il faut donner en paramètre du script le nom de votre VM perso pour configurer le remote-run"
    exit 1
fi