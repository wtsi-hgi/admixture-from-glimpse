#!/usr/bin/env python3

#identify related samples from IBD to remove before PCA

import argparse

def get_options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--infile", type=str, help='input file from plink --het')
    parser.add_argument("--outfile", type=str, help='outliers file')
    args = parser.parse_args()
    return args

def identify_samples_to_remove(infile, outfile):
    to_remove = {}
    with open (infile, 'r') as f:
        lines = f.readlines()
        for l in lines:
            ldata = l.split()
            if not ldata[9] == 'PI_HAT':
                pihat = float(ldata[9])
                id_1 = ldata[0] + "\t" + ldata[1]
                id_2 = ldata[2] + "\t" + ldata[3]
                if pihat > 0.1875: #cut off for 3rd degree relative
                    if (id_1 not in to_remove.keys()) and (id_2 not in to_remove.keys()):
                            to_remove[id_1] = 1
        
    with open(outfile, 'w') as o:
        o.write(("\n").join(to_remove.keys()))


def main():
    args = get_options()
    identify_samples_to_remove(args.infile, args.outfile)


if __name__ == '__main__':
    main()