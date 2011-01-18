#!/bin/sh
SCRIPTNAME=$0
processPrefix=$1
leng=$2
bgenome=$3
PREFIXPATH=$4
LIMITLENGTH=$5
bowtieQualFlag=$6
chrSizes=$7


SCRIPTPATH="$PREFIXPATH/scripts"
#BFQSPATH="$PREFIXPATH/bfqs"
MAPSPATH="$PREFIXPATH/maps"
#UNMAPSPATH="$PREFIXPATH/unmaps"
SELEXAOUTPUTSPATH="$PREFIXPATH/solexaOutputs"
SELEXASPLITSPATH="$PREFIXPATH/solexaSplits"

command="bowtie -S $bowtieQualFlag $bgenome $SELEXASPLITSPATH/$processPrefix.$leng.fastq $MAPSPATH/$processPrefix.$leng.sam.00 > $MAPSPATH/$processPrefix.$leng.map.stdout 2> $MAPSPATH/$processPrefix.$leng.map.stderr"
eval $command

#now propagate
newleng=`expr $leng - 1`
echo "nextlength=$newleng"

awk -v FS="\t" -v OFS="\t" '(substr($0,1,1)=="@" || $4>0)' $MAPSPATH/$processPrefix.$leng.sam.00 > $MAPSPATH/$processPrefix.$leng.sam
#make bam file
samtools view -bt $chrSizes -o $MAPSPATH/$processPrefix.$leng.bam $MAPSPATH/$processPrefix.$leng.sam

if [ $newleng -le $LIMITLENGTH ]
then 
	echo "<done of $processPrefix at $leng>"
else
	#convert the unmap entries to new split and propagate
	#awk -F"\t" '{printf "@%s\n%s\n+%s\n%s\n",$1,substr($3,0,length($3)-1),$1,substr($4,0,length($4)-1)}' "$UNMAPSPATH/$processPrefix.$leng.unmap" > "$SELEXASPLITSPATH/$processPrefix.$newleng.fastq"
	awk -v FS="\t" -v OFS="\t" -v newLeng=$newleng '{if(substr($0,1,1)!="@"){ if($4==0){printf("@%s\n%s\n+\n%s\n",$1,substr($10,1,newLeng),substr($11,1,newLeng));} }}' $MAPSPATH/$processPrefix.$leng.sam.00 > "$SELEXASPLITSPATH/$processPrefix.$newleng.fastq"
	#propagate by calling myself with new length (newleng)
	echo "propagate: $SCRIPTNAME $processPrefix $newleng $bgenome $PREFIXPATH $LIMITLENGTH"
	eval "$SCRIPTNAME $processPrefix $newleng $bgenome $PREFIXPATH $LIMITLENGTH \"\" $chrSizes" #don't propagate quality setting because the sam file output from which the new fastq are derived from are already in the probably Phred score. [$bowtieQualFlag]
fi

##echo "en"


