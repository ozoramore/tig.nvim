#!/bin/sh
# original is https://zenn.dev/iberianpig/articles/seamless_switching_between_vim_and_tui

gitroot="$(git rev-parse --show-superproject-working-tree --show-toplevel | head -1)"
echo edit "$1 $gitroot/$2" > /tmp/tig_callback # $1: line number, $2: file path
kill -1 $PPID #  terminate tig with SIGHUP.
