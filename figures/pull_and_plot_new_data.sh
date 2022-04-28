#!/bin/sh

pull_data=${1:-false}

dirlist=$(ls -d */ | grep -v Dadi_values | grep -v all_plots | grep -v tables) 

if $pull_data
then
	for j in $dirlist
	do
		echo ' '
		echo ${j}
		scp tyoeasley@128.252.185.7:/scratch/janine.bijsterbosch/WAPIAW_2/figure_plotting/${j}plotting* ${j}
	done
fi

for j in $dirlist
do 
	echo ' '
	echo $j
	i=$(find ${j}vi*.r)
	Rscript $i
done
