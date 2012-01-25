#!/bin/sh

echo "* Compilation du projet depuis le clone"
mvn clean install -Dmaven.test.skip
if [ $? -ne 0 ]; then
  echo ; echo ; echo ">>>> Erreur de compilation :("
  exit 1
fi
echo "* Exécution des tests depuis le clone"
mvn integration-test
if [ $? -ne 0 ]; then
  echo ; echo ; echo ">>>> Erreur lors de l'exécution des test :("
  exit 1
fi

