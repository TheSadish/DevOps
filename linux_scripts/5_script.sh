#!/bin/bash

read -p "Enter a string: " str

if [ -n "$str" ]
then
	echo "Non empty string"
else
	echo "Empty string"
fi
