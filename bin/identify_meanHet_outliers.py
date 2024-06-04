#!/usr/bin/env python3

#identify outliers after running plink --het
#example input file to work with
#output file is samples list

import argparse
import pandas as pd

def get_options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--infile", type=str, help='input file from plink --het')
    parser.add_argument("--outfile", type=str, help='outliers file')
    args = parser.parse_args()
    return args


def find_outliers(infile, outfile):
    '''
    calculate meanhet and exclude any samples where meanhet is outside of mean +/- 3SD
    '''
    df_het = pd.read_csv(infile, sep="\t")
    df_het['meanhet'] = (df_het['OBS_CT'] - df_het['O(HOM)'])/df_het['OBS_CT']
    meanhet = df_het['meanhet'].mean()
    sdhet3 = 3 * df_het['meanhet'].std()
    mean_plus_3sd = meanhet + sdhet3
    mean_minus_3sd = meanhet - sdhet3
    
    filtered_df = df_het.loc[(df_het['meanhet'] < mean_minus_3sd) | (df_het['meanhet'] > mean_plus_3sd)]
    filtered_df.to_csv(outfile, columns=['#FID', 'IID'], sep ='\t', index=False, header=False)

def main():
    args = get_options()
    find_outliers(args.infile, args.outfile)


if __name__ == '__main__':
    main() 