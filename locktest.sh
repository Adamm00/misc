#!/bin/sh
echo "Sleeping"
echo "$@" > /tmp/skynet.lock
echo "$$" >> /tmp/skynet.lock
date +%s >> /tmp/skynet.lock
sleep 1000