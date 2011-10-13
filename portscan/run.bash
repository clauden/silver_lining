#!/bin/bash
 

range=$1
range=${range:-"10.4.1.0/24"}   # this is palo alto vm network (?)

outfile="/tmp/nmap-$$.xml"
sudo nmap -v -oX $outfile "$range" 
ruby parse.rb $outfile
sudo rm $outfile
