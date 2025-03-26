#!/bin/bash

# Sciprt to monitor a process using process id and start accordingly if failed

ls /var/run/apache2/apache2.pid &> /dev/null

if [ $? -eq 0 ]
then
	echo "Apache is running "
else
	echo "Apache2 is not running"
	echo "Starting the process"
	systemctl start apache2
	if [ $? -ne 0 ]
	then
		echo "Apache couldn't be started"
	else
		echo "Apache process is started and running"
	fi
fi



