#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-07 15:01:31 +0000 (Fri, 07 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to generate DOCKER_STATUS.md containing all DockerHub / Docker Cloud repo build statuses for a user on a single page
#
# Usage:
#
# without arguments generates a page containing statuses for all DockerHub repos for your $DOCKER_USER
#
#   DOCKER_USER=harisekhon ./github_generate_status_docker.sh
#
# with arguments will only generate a page for those repos (repos will not be checked for existence but will get repo not found on the page itself)
#
# if not specifying the <user>/ prefix then auto prependeds $DOCKER_USER/
#
#   DOCKER_USER=harisekhon ./github_generate_status_page.sh  harisekhon/hbase harisekhon/zookeeper harisekhon/nagios-plugins ...
#
#   DOCKER_USER=harisekhon ./github_generate_status_page.sh  hbase zookeeper nagios-plugins ...

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

trap 'echo ERROR >&2' exit

cd "$srcdir"

file="DOCKER_STATUS.md"

repolist="$*"

# this leads to confusion as it generates some randomly unexpected output by querying a dockerhub user who happens to have the same name as your local user eg. hari, so force explicit now
#USER="${DOCKER_USER:-${USERNAME:-${USER}}}"
if [ -z "${DOCKER_USER:-}" ] ; then
    echo "\$DOCKER_USER not set!"
    exit 1
fi

if [ -z "$repolist" ]; then
    repolist="$(dockerhub_search.py -n 100 harisekhon | awk '/^harisekhon\/.*[[:space:]]\[OK]/{print $1}' | sort)"
fi

num_repos="$(wc -l <<< "$repolist")"
num_repos="${num_repos// /}"

{
cat <<EOF
# Docker Status Page

generated by \`${0##*/}\` in [HariSekhon/DevOps-Bash-tools](https://github.com/HariSekhon/DevOps-Bash-tools)

This page relies on shields.io which is slow so a lot of it may not load properly the first time so you may need to do one or more page reloads to get all the badges to load.

EOF
# don't expand `:latest`
# shellcheck disable=SC2016
echo "$num_repos docker repos - "'`:latest`'" tag build status:"
echo
for repo in $repolist; do
    if ! [[ "$repo" =~ / ]]; then
        repo="$DOCKER_USER/$repo"
    fi
    echo "[![Docker Build Status](https://img.shields.io/docker/cloud/build/$repo.svg)](https://hub.docker.com/r/$repo/builds)"
    echo "[![DockerHub Pulls](https://img.shields.io/docker/pulls/$repo.svg)](https://hub.docker.com/r/$repo) -"
    echo "[$repo](https://hub.docker.com/r/$repo)"
    echo
done
} | tee "$file"

trap '' exit
