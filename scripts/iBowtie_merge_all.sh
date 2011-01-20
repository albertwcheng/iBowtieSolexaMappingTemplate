#!/bin/sh

source fileUtils.sh

if [ $# -ne 2 ]; then
	echo "usage: " $0 "extReadFiles[txt,fastq,...] useCluster[y|n]"
	exit
fi

extReadFiles=$1
useCluster=$2

if [[ $useCluster == "y" ]]; then
	echo "use cluster version active"
elif [[ $useCluster == "n" ]]; then
	echo "standalone version active"
else
	echo "I don't understand useCluster=$useCluster option. say either y for yes or n for no"
	bash $0
	exit
fi

cd ..

PREFIXPATH=`pwd`;

SCRIPTPATH="$PREFIXPATH/scripts"
#BFQSPATH="$PREFIXPATH/bfqs"
MAPSPATH="$PREFIXPATH/maps"
#UNMAPSPATH="$PREFIXPATH/unmaps"
SELEXAOUTPUTSPATH="$PREFIXPATH/solexaOutput"
SELEXASPLITSPATH="$PREFIXPATH/solexaSplits"
BAMPATHMERGED="$PREFIXPATH/bammerged";

solexaFiles=(`ls $SELEXAOUTPUTSPATH/*.$extReadFiles`)

nSolexaFiles=${#solexaFiles[@]}

requestEmptyDirWithWarning $BAMPATHMERGED

for((i=0;i<$nSolexaFiles;i++))
do
	solFile=`basename ${solexaFiles[$i]}`
	solFileNoExt=${solFile/.$extReadFiles/}
	echo $solFileNoExt
	echo "samtools merge $BAMPATHMERGED/${solFileNoExt}.bam $MAPSPATH/split_${solFile}*.bam; samtools sort $BAMPATHMERGED/${solFileNoExt}.bam  $BAMPATHMERGED/${solFileNoExt}.sorted; samtools index $BAMPATHMERGED/${solFileNoExt}.sorted.bam" > $BAMPATHMERGED/${solFileNoExt}.sh
	if [[ $useCluster == "y" ]]; then
		bsub bash $BAMPATHMERGED/${solFileNoExt}.sh
	else
		bash $BAMPATHMERGED/${solFileNoExt}.sh	
	fi
done

