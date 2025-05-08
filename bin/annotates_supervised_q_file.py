#!/usr/bin/env python3
import sys

def add_annotation(qfile, famfile, popfile):
    sample_list=[]
    with open(famfile, "r") as samples:
        for line in samples:
            sample_list.append(line.strip())

    pop_list=[]
    with open(popfile, "r") as pops:
        for line in pops:
            pop_list.append(line.strip())

    annotated_file="supervised_admixture_"+qfile.split(".")[1]+".Q.with_sample_and_pop"
    with open(qfile, "r") as infile, open(annotated_file, "w") as outfile:
        i=0
        for line in infile:
            outfile.write(sample_list[i]+"\t"+line.strip()+"\t"+pop_list[i]+"\n")
            i+=1

def main():
    qfile=sys.argv[1]
    famfile=sys.argv[2]
    popfile=sys.argv[3]
    add_annotation(qfile, famfile, popfile)

if __name__ == '__main__':
    main() 
