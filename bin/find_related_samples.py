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
    pairs = []
    control_removed_count = 0
    to_remove = set()
    
    # Read input file and collect pairs with PI_HAT values
    with open(infile, 'r') as f:
        lines = f.readlines()
        for l in lines:
            ldata = l.split()
            if  ldata[9] != 'PI_HAT':
                pihat = float(ldata[9])
                id_1 = ldata[1]
                id_2 = ldata[3]
                if pihat > 0.1875:  # Cutoff for 3rd degree relatives
                    # Remove any control samples that have high relatedness with any others
                    if not id_1.startswith("EGAN") or not id_2.startswith("EGAN"):
                        if not id_1.startswith("EGAN"):
                            if id_1 not in to_remove:
                                to_remove.add(id_1)
                                control_removed_count += 1
                        else:
                            if id_2 not in to_remove:
                                to_remove.add(id_2)
                                control_removed_count += 1
                    else:
                        pairs.append((id_1, id_2, pihat))

    # Warn if any control samples were removed
    if control_removed_count > 0:
        print("Warning: ", control_removed_count, "control samples were flagged as related and removed.")


    # Iterate through pairs by removing the most frequently occurring sample
    while pairs:
        # Count occurrences of each sample in the remaining pairs
        sample_counts = {}
        for id_1, id_2, _ in pairs:
            sample_counts[id_1] = sample_counts.get(id_1, 0) + 1
            sample_counts[id_2] = sample_counts.get(id_2, 0) + 1
    

        # Identify the sample with the highest occurrence - if it is a draw it picks the first one
        remove_sample = max(sample_counts, key=lambda k: sample_counts[k])
        
        # Add sample to the removal list
        to_remove.add(remove_sample)

        # Remove all pairs containing the selected sample
        pairs = [pair for pair in pairs if remove_sample not in pair]


    # Write the output file with the list of samples to remove
    with open(outfile, 'w') as o:
        o.write("\n".join([f"{item}\t{item}" for item in to_remove]))


def main():
    args = get_options()
    identify_samples_to_remove(args.infile, args.outfile)

if __name__ == '__main__':
    main()
