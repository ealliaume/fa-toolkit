#!/bin/sh

. `dirname $0`/safe-commons
VERBOSE="pas de dump des logs depuis les validateurs -- voir safe-commons/errorHandler"

PERSONAL_VM=$1

log "Compilation du projet depuis le clone, TU et TI"
mvn clean install 
errorHandler "Erreur de compilation"
