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
TYPE_SPEED=600

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=0

# No wait
export NO_WAIT=true

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

# ./run-k8s-full.sh

[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-jenkins-x && cd k8s-jenkins-x

sed docs/part-0{1..3}/README.md \
  -e '/^## Configure AWS/,/^## Install Jenkins X/d' \
| \
sed -n '/^```bash$/,/^```$/p;/^-----$/p' \
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


if [ "$#" -eq 0 ]; then
  source README.sh
else
  cat README.sh
fi
