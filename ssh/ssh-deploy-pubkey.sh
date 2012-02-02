#!/bin/bash
# @param $1 SSH connection data 'user@host'

PUBKEY_FILE=~/.ssh/id_rsa.pub
PUBKEY=`cat $PUBKEY_FILE`
# @todo Check existence of key in authorized_keys
ssh $1 "echo $PUBKEY >> ~/.ssh/authorized_keys"
