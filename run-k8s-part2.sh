#!/usr/bin/env bash

set -eu

################################################
# include the magic
################################################
test -s ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
. ./demo-magic.sh

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=60

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=0

# No wait
export NO_WAIT=false

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

# hide the evidence
#clear

### Please run these commands before running the script

# docker run -it --rm -e USER -e GITHUB_TOKEN -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -v $HOME/.config/hub:/root/.config/hub:ro -v $PWD:/mnt ubuntu
# echo $(hostname -I) $(hostname) >> /etc/hosts
# apt-get update -qq && apt-get install -qq -y curl git pv > /dev/null
# cd /mnt

# ./run-k8s-part2.sh

[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-jenkins-x && cd k8s-jenkins-x

sed -n '/^```bash$/,/^```$/p;/^-----$/p' docs/part-0{2..3}/README.md \
| \
sed \
  -e 's/^-----$/\
p  ""\
p  "################################################################################################### Press <ENTER> to continue"\
wait\
/' \
  -e 's/^```bash.*/\
pe '"'"'/' \
  -e 's/^```$/'"'"'/' \
> README.sh

export MY_DOMAIN=${MY_DOMAIN:-mylabs.dev}

if [ "$#" -eq 0 ]; then

  if [ -z ${GITHUB_TOKEN} ] || [ -z ${AWS_ACCESS_KEY_ID} ] || [ -z ${AWS_SECRET_ACCESS_KEY} ]; then
    echo -e "\n*** One of the mandatory variables is not set !!\n";
    exit 1
  fi

  echo "*** ${MY_DOMAIN} ***"

  echo -e "\n\n*** Press ENTER to start\n"
  read A

  # hide the evidence
  clear
  source README.sh
else
  cat README.sh
fi
