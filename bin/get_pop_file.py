#!/usr/bin/env python3
import sys

def get_column_names(input_file):
    with open(input_file, "r") as columns:
        i = 0
        for line in columns:
            if i == 0:
                sample_column=line.strip()
            elif i == 1:
                pop_column = line.strip()
            i += 1
    return sample_column, pop_column

def get_pop(input_name, sample_column, pop_column, info_file):
    fam_file = input_name + ".fam"
    pop_file = input_name + ".pop"
    pop_dict = {}

    with open(info_file, "r") as pop_info:
        header=pop_info.readline().strip().split("\t")
        sc = header.index(sample_column)
        pc = header.index(pop_column)
        for line in pop_info:
            sample = line.split("\t")[sc]
            pop = line.split("\t")[pc]
            pop_dict[sample] = pop

    with open(fam_file, "r") as infile, open(pop_file, "w") as outfile:
        for line in infile:
            sample = line.split("\t")[0]
            outfile.write(pop_dict.get(sample, "-")+"\n")

def main():
    input_name=sys.argv[1]
    columns=sys.argv[2]
    info_file=sys.argv[3]
    sample_column, pop_column = get_column_names(columns)
    get_pop(input_name, sample_column, pop_column, info_file)

if __name__ == '__main__':
    main() 
