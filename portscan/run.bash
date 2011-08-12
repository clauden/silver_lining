#!/bin/bash
 

range=$1
range=${range:-"10.4.1.0/24"}   # this is palo alto vm network (?)

echo sudo nmap "$range" -v -oX /tmp/nmap-$$.xml
ruby parse.rb /tmp/nmap-$$.xml 
