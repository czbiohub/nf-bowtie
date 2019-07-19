#!/usr/bin/env python
import csv
import sys

f = csv.reader(sys.stdin, dialect="excel-tab")
of = csv.writer(sys.stdout, dialect="excel-tab")
last_read = None
for line in f :
   #take care of the header
   if(line[0][0] == "@") :
       of.writerow(line)
       continue

   if(last_read == None) :
       last_read = line
   else :
       if(last_read[0] == line[0]) :
           of.writerow(last_read)
           of.writerow(line)
           last_read = None
       else :
           last_read = line
