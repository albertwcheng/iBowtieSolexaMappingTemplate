#!/bin/bash

source fileUtils.sh
echo -ne "Clean. Do you want to clean input sequences as well [y/n]?"
read cleanSequencesAsWell


if [ ${#cleanSequencesAsWell} -gt 0 ] && [ $cleanSequencesAsWell == "y" ]; then
	echo "also clean sequences"
	removeAndMkDirIfExist ../solexaOutput
	#mkdir ../selexaOutput
fi

removeIfExist ../maps
removeIfExist ../solexaSplits
removeIfExist ../unmaps
