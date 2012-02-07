#!/bin/sh
# @author Christophe Amory
# @author Xavier Bucchiotty
# @author Cédric Pineau
# Remote run

echo "Installation de git"
sudo apt-get update
sudo apt-get install git

echo "Installation de Protobuff"

if [ 0 -eq `grep http://rodolphe.quiedeville.org/debian /etc/apt/sources.list | wc -l `]; then
	sudo sh -c 'echo "deb http://rodolphe.quiedeville.org/debian squeeze-backports main" >> /etc/apt/sources.list'
fi
sudo apt-get update
sudo apt-get install libprotobuf-dev protobuf-compiler

echo "Untar du fichier des fichiers de config et maven"
cd ~ 
tar -xvf jboss.tar
tar -xvf maven.tar
tar -xvf m2.tar
mv m2 .m2
rm jboss.tar
rm maven.tar
rm m2.tar
mv bashrc .bashrc

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


echo "Préparation de la partie JBOSS"
cd ~/jboss-4.0.5.GA/server/insito/
rm -rf ./insito-data
ln -s ~/remote-run/data ./insito-data 
rm -rf ./deploy/*.ear
rm -rf ./deploy/*.war
ln -s ~/remote-run/ear/ear/target/finactive-ear.ear ./deploy/insito.ear

cd

echo "Installation OK"
