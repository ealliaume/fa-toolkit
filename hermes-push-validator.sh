#!/bin/sh

. `dirname $0`/safe-commons
VERBOSE="pas de dump des logs depuis les validateurs -- voir safe-commons/errorHandler"

log "Compilation du projet depuis le clone"
mvn clean install -Dmaven.test.skip
errorHandler "Erreur de compilation"

log "Exécution des tests depuis le clone"
mvn test
errorHandler "Erreur lors de l'exécution des tests"

