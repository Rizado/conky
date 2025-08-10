#!/bin/bash
cd "$(dirname "$0")" || exit
sleep 1
( set -x; setsid conky -c conky.conf )
sleep 1
exit
