#!/bin/sh
mkdir -p /sys/fs/cgroup/mydockr
echo $$ > /sys/fs/cgroup/mydockr/cgroup.procs
