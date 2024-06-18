#!/usr/bin/env python3

#annotate output from admixture with population

import argparse

def get_options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--q_file", type=str, help='admixture Q file annotated with sample name')
    parser.add_argument("--pops_file", type=str, help='sample population mapping')
    parser.add_argument("--outfile", type=str, help='outliers file')
    args = parser.parse_args()
    return args


def annotate_q_file(q_file, pops_file, outfile):
    pops = {}
    with open(pops_file, 'r') as p:
        lines = p.readlines()
        for l in lines:
            if not l.startswith('Sample'):
                linedata = l.split('\t')
                sample = linedata[0]
                pop = linedata[3]
                superpop = linedata[5]
                if not ',' in pop:#1 sample has 2 pop codes separated by a comma, we want to skip this
                    pops[sample] = {}
                    pops[sample]['pop'] = pop
                    pops[sample]['superpop'] = superpop

    with open(outfile, 'w') as o:
        with open(q_file, 'r') as q:
            lines = q.readlines()
            for l in lines:
                l = l.rstrip()
                linedata = l.split()
                s = linedata[0]
                pop = '-'
                superpop = '-'
                if s in pops.keys():
                    pop = pops[s]['pop']
                    superpop = pops[s]['superpop']

                outline = l + '\t' + pop + '\t' + superpop + '\n'
                o.write(outline)


def main():
    args = get_options()
    annotate_q_file(args.q_file, args.pops_file, args.outfile)


if __name__ == '__main__':
    main()