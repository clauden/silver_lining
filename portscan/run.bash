#!/bin/bash
 

range=$1
range=${range:-"10.4.1.0/24"}   # this is palo alto vm network (?)

xoutfile="/tmp/nmap-$$.xml"
goutfile="/tmp/nmap-$$.txt"
sudo nmap --host-timeout 120s -v -sT -oG $goutfile -oX $xoutfile "$range" 

# nmap's xml output doesnt seem as stable as grep...
# ruby parse-grep.rb $goutfile
ruby parse-grep.rb $goutfile

sudo rm $xoutfile
sudo rm $goutfile
