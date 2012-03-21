#!/bin/sh
# @author Christophe Amory
# @author Xavier Bucchiotty
# @author Cédric Pineau
# Remote run

echo "Installation de git"
sudo apt-get update
sudo apt-get install git

echo "Installation de Protobuff"

if [ 0 -eq `grep http://rodolphe.quiedeville.org/debian /etc/apt/sources.list | wc -l ` ]; then
	sudo sh -c 'echo "deb http://rodolphe.quiedeville.org/debian squeeze-backports main" >> /etc/apt/sources.list'
fi
sudo apt-get update
sudo apt-get install libprotobuf-dev protobuf-compiler

echo "Untar du fichier des fichiers de config et maven"
cd ~ 
if [ -f maven.tar ]; then
	tar -xvf maven.tar
	rm maven.tar
fi

if [ -f m2.tar ]; then
        tar -xvf m2.tar
        rm m2.tar
	mv m2 .m2
fi

if [ -f bashrc ]; then
	mv bashrc .bashrc
fi

if [ -f properties-service.xml ]; then
	mv properties-service.xml /home/service/jboss-4.0.5.GA/server/insito/deploy
fi

if [ ! -d ~/.ssh ]; then
echo "Création d'un répertoire ~/.ssh"
mkdir ~/.ssh
chmod 700 ~/.ssh
fi

if [ ! -d ~/remote-run ]; then
	echo "Préparation du repo git de remote run"
	mkdir ~/remote-run
	cd ~/remote-run
	git init .
	git config receive.denyCurrentBranch ignore
	git config receive.denyDeleteCurrent ignore
	echo "Repo créé sur ${HOME}/remote-run"
else
	echo "Vous avez déjà votre repo \"remote-run\""
fi

# Ajout de la variable specifiant le repertoire de configuration relatif a chaque developpeur
echo export REMOTE_CONF_DIR=/home/service/remote-run/data/conf/developpement/${HOSTNAME} >> /home/service/.bashrc


echo "Préparation de la partie JBOSS"
cd ~/jboss-4.0.5.GA/server/insito/
rm -rf ./insito-data
ln -s ~/remote-run/data ./insito-data 
rm -rf ./deploy/*.ear
rm -rf ./deploy/*.war
ln -s ~/remote-run/ear/ear/target/finactive-ear.ear ./deploy/insito.ear

cd

echo "Installation OK"
