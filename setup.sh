#!/bin/bash

apt-get update
apt-get -y install cowsay fortune

echo 'exec /usr/games/fortune | /usr/games/cowsay -f $(ls /usr/share/cowsay/cows/ | shuf | head -n1)' > ~/.bashrc