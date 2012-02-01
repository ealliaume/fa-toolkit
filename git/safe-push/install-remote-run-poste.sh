log() {
  echo "\033[0;32m* "$1"\033[0m"
}

if [ $# -eq 0 ]; then
	echo "Il faut passer en paramètre du script le nom de votre VM"
	exit 1
fi

if [ ! -d ./.git ]; then
	echo "Le script doit être lancé depuis le répertoire principale de votre projet git"
	exit 1
fi
	log "Upload de votre clé sur votre VM"
 	curl https://raw.github.com/olemerdy-fa/toolinux/master/macosx/ssh-deploy-pubkey.sh --output ssh-deploy-pubkey.sh
	sh ./ssh-deploy-pubkey.sh service@$1
	if [ $? -ne 0 ]; then
		echo ">>ERREUR LORS DE L'UPLOAD DE VOTRE CLE"
	fi
rm ssh-deploy-pubkey.sh

if [ 0 -eq ` grep PERSONAL_VM ~/.profile | wc -l` ]; then
	log "Ajout de la variable d'environnement dans .profile"
	echo "export \$PERSONAL_VM=$1" >> ~/.profile
else
	log "Vous avez déjà initialiser votre PERSONAL_VM"
fi

log "Test de connection à la VM: ssh service@$PERSONAL_VM"
ssh service@$PERSONAL_VM echo "Connection OK"

log "Ajout du remote \"remote-run\" dans git"
git remote add remote-run service@$PERSONAL_VM:/home/service/remote-run

log "Initialisation du repo distant"
git push remote-run +HEAD:master

log "Test de compilation sur le repo distant"
ssh service@$PERSONAL_VM ". ~/.bashrc; cd ~/remote-run/; git checkout -f; mvn install -Dmaven.test.skip"

echo
log "Installation OK"