#! /bin/bash
#
# Usage
#
#   update_varscan2.sh listfile
#
# where listfile contains a list of tab delimited ref-tumor samples
#

listfn=$1
if [ -z $listfn ] ; then 
  echo "Provide a tab delimited file with bamfile names" 
  exit 1
fi

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
echo $BASEDIR

onceonly="~/izip/git/opensource/ruby/once-only/bin/once-only"
mkdir -p varscan2

IFS=$'\t'
while read ref tumor ; do
  echo "tumor=$tumor ref=$ref"
  for x in $tumor $ref ; do 
    name="${x%.*}_full_kinome_CoDeCZ_chr17"
    echo "==== Create samtools mpileup of $x (name $name)"
    echo "~/opt/bin/samtools mpileup -B -f /data/GENOMES/human_GATK_GRCh37/GRCh37_gatk.fasta ../$x > $name.mpileup"|~/izip/git/opensource/ruby/once-only/bin/once-only --pfff -v -d varscan2
  done
  ref2="${ref%.*}_full_kinome_CoDeCZ_chr17"
  tumor2="${tumor%.*}_full_kinome_CoDeCZ_chr17"
  echo "==== Running varscan2 on $ref (ref $ref2)"
  echo "java -jar ~/opt/lib/VarScan.v2.3.6.jar somatic $ref2.mpileup $tumor2.mpileup $ref2-varscan --min-coverage 10 --somatic-p-value 0.001" | ~/izip/git/opensource/ruby/once-only/bin/once-only --pfff -d varscan2 -v --debug

  echo "==== Index with Samtools $tumor2.bam ..."
  echo "samtools index $tumor2.bam"| ~/izip/git/opensource/ruby/once-only/bin/once-only --pfff -d . -v
  echo "==== Readcount on tumor $tumor2..."
  echo "~/opt/bin/bam-readcount -w 5 -f /data/GENOMES/human_GATK_GRCh37/GRCh37_gatk.fasta  ../$tumor2.bam 17 > $tumor2.readcount"| ~/izip/git/opensource/ruby/once-only/bin/once-only --pfff -d varscan2 -v
  echo "Running fpfilter using ref $ref2..."
  echo "perl $HOME/opt/bin/fpfilter.pl --output-basename $tumor2 $ref2-varscan.snp $tumor2.readcount"|~/izip/git/opensource/ruby/once-only/bin/once-only --pfff -d varscan2 -v 

done < $listfn



