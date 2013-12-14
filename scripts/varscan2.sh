#! /bin/bash
#
# Usage
#
#   update_varscan2.sh listfile
#
# where listfile contains a list of tab delimited ref-tumor samples
#

# Default settings
REFSEQ=/data/GENOMES/human_GATK_GRCh37/GRCh37_gatk.fasta
SAMTOOLS=$HOME/opt/bin/samtools
SAMBAMBA=$HOME/opt/bin/sambamba
ONCEONLY="$HOME/izip/git/opensource/ruby/once-only/bin/once-only"
BED="$HOME/full_kinome_CoDeCZ_chr17.bed"

if [ $1 == "--config" ]; then
  config=$2
  shift ; shift
  . ./$config
fi
normalname=$1
tumorname=$2
normal=$3
tumor=$4

phred=30  # 1:1000
onceonly=$ONCEONLY
refgenome=$REFSEQ
samtools=$SAMTOOLS
sambamba=$SAMBAMBA
bed=$BED

mkdir -p varscan2

echo "tumor=$tumor normal=$normal"

ref=$normal
for x in $normal $tumor ; do 
  echo "==== Index with Samtools $x ..."
  echo "$sambamba index $x"| $onceonly --pfff -d . -v
  echo "==== Index fasta with samtools ..."
  echo "$samtools faidx $refgenome"|$onceonly --pfff -d . -v
  echo "==== Create samtools mpileup of $x"
  # check -E option
  echo "$samtools mpileup -B -q $phred -f $refgenome -l $bed ../$x > $x.mpileup"|$onceonly --pfff -v -d varscan2 --skip $x.mpileup
done


# --mpileup 1 option (newer undocumented scoring)
echo "java -jar $HOME/opt/lib/VarScan.v2.3.6.jar somatic $normal.mpileup $tumor.mpileup $normal-$tumor.varScan.output --min-coverage-normal 5 --min-coverage-tumor 8 --somatic-p-value 0.001 --strand-filter --min-var-freq 0.20"|$onceonly --pfff -v -d varscan2

echo "java -jar ~/opt/lib/VarScan.v2.3.6.jar processSomatic $normal-$tumor.varScan.output.snp"|$onceonly -v -d varscan2 --skip $normal-$tumor.varScan.output.snp

# The following runs the alternative readcount tools (older scoring)
#
echo "==== Readcount on tumor $tumor..."
echo "~/opt/bin/bam-readcount -b $phred -w 5 -f $refgenome  ../$tumor 17 > $tumor.readcount"|$onceonly --pfff -d varscan2 -v --skip $tumor.readcount
echo "Running fpfilter using ref $ref..."
echo "perl $HOME/opt/bin/fpfilter.pl --output-basename $tumor $normal-$tumor.varScan.output.snp $tumor.readcount" | $onceonly --pfff -d varscan2 -v

