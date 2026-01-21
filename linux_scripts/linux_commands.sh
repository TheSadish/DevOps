#!/bin/bash

set -x # Enable debug mode to print each command before executing
#set -e # Exit immediately if a command exits with a non-zero status
#set -o pipefail # Return the exit status of the last command in the pipeline that failed


df -h


free -g

nproc

pwd

cat test.txt | awk -F" " '$4 > 4000 {print $4}'