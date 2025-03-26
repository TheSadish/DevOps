#/bin/bash

read -p "Enter a number :" num

if [ $num -gt 100 ]
then
    echo "Num > 100"
elif [ $num -lt 50 ]
then
    echo "Num < 50"
else
    echo "50 >= Num >= 100"
fi

