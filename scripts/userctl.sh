#!/bin/bash

USERS_FILE="./hysteria/users.yaml"

generate_uuid() {
  cat /proc/sys/kernel/random/uuid
}

add_user() {
  NAME=$1
  if [ -z "$NAME" ]; then
    echo "Usage: $0 add <username>"
    exit 1
  fi

  TOKEN=$(generate_uuid)

  echo "  - name: $NAME
    password: $TOKEN" >> $USERS_FILE

  echo ""
  echo "User created:"
  echo "Name: $NAME"
  echo "Token: $TOKEN"
  echo ""
  echo "Client config:"
  echo "---------------------------------"
  echo "server: vpn.example.com:443"
  echo ""
  echo "auth: $TOKEN"
  echo ""
  echo "tls:"
  echo "  sni: vpn.example.com"
  echo "  insecure: false"
  echo ""
  echo "transport:"
  echo "  type: udp"
  echo "---------------------------------"
  echo ""

  docker compose restart hysteria
}

list_users() {
  grep "name:" $USERS_FILE | awk '{print $3}'
}

delete_user() {
  NAME=$1
  if [ -z "$NAME" ]; then
    echo "Usage: $0 del <username>"
    exit 1
  fi

  awk -v user="$NAME" '
    BEGIN {skip=0}
    $0 ~ "name: "user {skip=1; next}
    skip && $0 ~ "password:" {skip=0; next}
    !skip {print}
  ' $USERS_FILE > tmp.yaml

  mv tmp.yaml $USERS_FILE

  docker compose restart hysteria
  echo "User $NAME deleted."
}

show_user() {
  NAME=$1
  awk -v user="$NAME" '
    $0 ~ "name: "user {getline; print}
  ' $USERS_FILE
}

case "$1" in
  add) add_user $2 ;;
  del) delete_user $2 ;;
  list) list_users ;;
  show) show_user $2 ;;
  *) echo "Usage: $0 {add|del|list|show} <username>" ;;
esac
