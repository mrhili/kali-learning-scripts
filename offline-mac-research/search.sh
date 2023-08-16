#!/bin/bash

locateoui="/usr/share/ieee-data/oui.txt"

MAC="$(echo $1 | sed 's/ //g' | sed 's/-//g' | sed 's/://g' | cut -c1-6)";

result="$(grep -i -A 4 ^$MAC $locateoui)";

if [ "$result" ]; then
	echo "For the MAC $1 the following information is found:"
	echo "$result"
else
	echo "MAC $1 is not found in the database."
fi
