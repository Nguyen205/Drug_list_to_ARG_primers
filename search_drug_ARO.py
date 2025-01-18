# -*- coding: utf-8 -*-
"""
Created on Tue Jan  7 15:53:32 2025

@author: 67535
"""

from owlready2 import *
import argparse

parser = argparse.ArgumentParser(description='Use a list of drug names to search for the drug AROs')

parser.add_argument('-o', '--output', required = False,
                    help='Output file path and name containing all available AROs, suffix not needed. Default: ./output/drug_AROs',default='./output/drug_AROs')
parser.add_argument('-i', '--input',required = True,
                    help='Input txt file path listing the drugs of interest.')

args = parser.parse_args()

onto=get_ontology("http://purl.obolibrary.org/obo/aro.owl").load()

file=open(args.input)
drug_list=file.readlines()
file.close()

drugs_not_found=[]
drug_AROs=[]
drugs_found=[]

for i in range(0,len(drug_list)):
    drug_list[i]=drug_list[i].strip('\n')
    a=str(onto.search(label=drug_list[i],_case_sensitive=False))
    if len(a)>2:
        a=a.split('ARO_')[1].split(']')[0]
        drug_AROs.append(a)
        drugs_found.append(drug_list[i])
    else:
        drugs_not_found.append(drug_list[i])

if drugs_not_found!=[]:
    print('The AROs of the drugs listed below were not found, please check the spelling or change to other synonyms and try again:')        
    print(drugs_not_found)
    print('\n')
    drug_not_found_output=open(args.output.split('drug_AROs')[0]+'drugs_not_found_try_other_synonyms.txt','w')
    for i in range(0,len(drugs_not_found)):
        print(drugs_not_found[i],file=drug_not_found_output)
    drug_not_found_output.close()
print('The AROs of the following drugs were found:')
print(drugs_found)
print(drug_AROs)

ARO_output=open(args.output+'.txt','w')
for i in range(0,len(drug_AROs)):
    print(drug_AROs[i],file=ARO_output)
ARO_output.close()

