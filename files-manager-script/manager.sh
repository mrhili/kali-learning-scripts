#!/bin/bash



list_files(){



	echo "Files direcrories"

	ls -l



}













while true; do



	echo "----------------------------"

	echo "File Mangement script by amineonline"

	echo "----------------------------"

	echo "type 1 for listing files"

	echo "type 2 for changing directory"

	echo "type 3 for serching file by extension"

	#echo "type 4 for "

	echo "type q for quitting"



	read -p "Enter choice: " choice

	

	case $choice in

	

	1)

		

		list_files

			

		;;

	2)

		

		read -p "Enter directory path " dir_path

		

		cd "$dir_path" || echo "Path not found"

			

		;;

	3)

		

		read -p "Enter file extension " extension

		

		find . -type f -name "*.$extension" -exec ls -l {} \;

			

		;;

	

	q)

		exit 0

		;;

	*)

		

		echo "Type correctly"

			

		;;

			

	esac



	

done