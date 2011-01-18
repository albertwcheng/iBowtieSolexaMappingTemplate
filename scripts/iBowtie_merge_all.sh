#!/bin/sh

source fileUtils.sh

if [ $# -lt 1 ]; then
	echo "usage: " $0 "extReadFiles[txt,fastq,...]"
	exit
fi

extReadFiles=$1

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
	bsub bash $BAMPATHMERGED/${solFileNoExt}.sh
done

