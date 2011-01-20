#!/bin/bash

source fileUtils.sh


if [ $# -ne 7 ]; then
	echo "usage: " $0 "readLength limitLength[14] genome[hg18|mm9] extReadFiles[txt,fastq,...] bowtieQualFlag['','--solexa1.3-quals','--solexa-quals' etc see bowtie manual for details for the first run only] extOptsToBowtie[e.g., --best] useCluster[y|n]"
	echo "use guessFastQTypeForFiles.sh to guess type and length of files if you are not sure. See README in top directory for details"
	exit
fi

leng=$1 ###
LIMITLENGTH=$2 ###
READPERJOB=2000000 ####
JOBSPLITLINES=`expr $READPERJOB "*" 4`

genome=$3
genomeSrcFile=genomeSource/$genome
extReadFiles=$4
bowtieQualFlag=$5
extOptsToBowtie=$6
useCluster=$7

if [[ $useCluster == "y" ]]; then
	echo "use cluster version active"
elif [[ $useCluster == "n" ]]; then
	echo "standalone version active"
else
	echo "I don't understand useCluster=$useCluster option. say either y for yes or n for no"
	bash $0
	exit
fi

#exit

if [ ! -e $genomeSrcFile ]; then
	echo "genome unknown: you need to build a bowtie index (or download from bowtie sourceforge page) for it and add the bowtie index prefix to genomeSource/genome"
	echo "alternative known genome:"
	ls genomeSource
	exit
fi

source $genomeSrcFile
#bgenome=bowtie_index_prefix  e.g., /lab/jaenisch_albert/genomes/mm8/bowtieIndex/mm8
#chrSizes=chrsize.list     e.g., /lab/jaenisch_albert/genomes/mm8/mm8_nr.sizes

cd .. #go up one level

if [ ! -e solexaOutput/* ]
then
	echo "solexaOutput contains no files. Put solexaOutput qualityScore files into directory selexaOutput"
	exit 0
fi

echo "mapping to genome $genome"
echo "using bfa $bgenome"
echo "read length is $leng, iterative to length $LIMITLENGTH"
if [[ $useCluster == "y" ]]; then
	echo "Spliting reads to $READPERJOB per job (" $JOBSPLITLINES " lines)"
fi
echo "The read files are"
ls solexaOutput/*.$extReadFiles


#exit

PREFIXPATH=`pwd`;

SCRIPTPATH="$PREFIXPATH/scripts"
MAPSPATH="$PREFIXPATH/maps"
#UNMAPSPATH="$PREFIXPATH/unmaps"
SELEXAOUTPUTSPATH="$PREFIXPATH/solexaOutput"
SELEXASPLITSPATH="$PREFIXPATH/solexaSplits"

requestEmptyDirWithWarning $SELEXASPLITSPATH #request empty directory for storing the split files
requestEmptyDirWithWarning $MAPSPATH #request empty directory for storing the map result from maq
#requestEmptyDirWithWarning $UNMAPSPATH #request empty directory for stroing the unmap file	


cd $SELEXAOUTPUTSPATH #enter directory of selexa output

for i in *.$extReadFiles; do  #the extension of selexa output is *.txt?
	if [[ $useCluster == "y" ]]; then
		echo "spliting file $i"; 
		split -l $JOBSPLITLINES $i "../solexaSplits/split_$i" #split selexa output to chunks of 2million entries (4 lines per entries)
	else
		ln $i ../solexaSplits/split_$i
	fi
done; 

cd ..


cd $SELEXASPLITSPATH #go to the directory with the split selexa files

for i in split_*; do #for each chunks of sequences

	ln $i "$i.$leng.fastq";

	if [[ $useCluster == "y" ]]; then
		bsub -o "$MAPSPATH/$i.mapping.stdout" -e "$MAPSPATH/$i.mapping.stderr"  "$SCRIPTPATH/iBowtie_mapSelexa_full_step.sh" $i $leng $bgenome $PREFIXPATH $LIMITLENGTH "$bowtieQualFlag" $chrSizes "$extOptsToBowtie"
	else
		bash "$SCRIPTPATH/iBowtie_mapSelexa_full_step.sh" $i $leng $bgenome $PREFIXPATH $LIMITLENGTH "$bowtieQualFlag" $chrSizes "$extOptsToBowtie" > "$MAPSPATH/$i.mapping.stdout" 2> "$MAPSPATH/$i.mapping.stderr"  
	fi
done;

echo "<Done> Now wait for the queue for mapping to finish"
