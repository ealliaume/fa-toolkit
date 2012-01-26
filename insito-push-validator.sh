#!/bin/sh

. `dirname $0`/safe-commons
VERBOSE="pas de dump des logs depuis les validateurs -- voir safe-commons/errorHandler"

PERSONAL_VM=$1

log "Compilation du projet depuis le clone"
mvn clean install -Dmaven.test.skip
errorHandler "Erreur de compilation"

log "Exécution des tests depuis le clone"
mvn integration-test
errorHandler "Erreur lors de l'exécution des tests"

log "Construction du ZIP pour envoi sur VM"
/opt/local/bin/mvn package -Dmaven.test.skip -PpackageEarData
errorHandler "Erreur de la génération du zip"

log "Deploiement de l'application sur un vm de test"
scp ear/ear/target/earData.zip service@$PERSONAL_VM:/home/service/consoleUploadedFile
errorHandler "Erreur lors du déploiement de l'application sur $PERSONAL_VM"

log "Démarrage du JBOSS sur $PERSONAL_VM"
ssh service@$PERSONAL_VM "/home/service/service.sh refresh"
errorHandler "Erreur lors du démarrage de JBOSS"

log "Application deployée, lancement des tests fonctionnels"
mvn test -PoldTestsFonctionnels -Dtest=com.financeactive.insito.RunAllTests
errorHandler "Erreur lors des tests fonctionnels"

log "Tests fonctionnels OK, arrêt de l'instance JBOSS"
ssh service@$PERSONAL_VM "/home/service/service.sh stop"


