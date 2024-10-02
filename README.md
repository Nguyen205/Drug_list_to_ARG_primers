# Drug_list_to_ARG_primers
Metagenomic sequencing results can guide the design of qPCR primers and probes. This is a pipeline for designing qPCR primers and probes targeting the ARGs of interest based on metagenomic sequencing results and a list of antibiotics of interest. 

## Description
Metagenomic sequencing and qPCR are two mainstream methods for detecting antibiotic resistance genes (ARGs) in complex DNA samples (e.g., wastewater, stool, etc.). Metagenomic sequencing can detect a wide range of ARGs without targeting them, while qPCR requires primer and probe design for each ARG. However, metagenomic sequencing is more expensive, harder to perform, and less sensitive than qPCR. Therefore, for routine ARG surveillance, it is more practical to use metagenomic sequencing at the beginning to determine the range of target ARGs and design qPCR primers and probes accordingly. In addition, metagenomic sequencing can detect the mutated sites in ARGs. To achieve better qPCR efficiencies, these mutated sites should be avoided in primer and probe design. Hundreds of ARGs may be found in metagenomic sequencing, but not all ARGs should be included in routine qPCR surveillance. This pipeline fills the gap between metagenomic sequencing and qPCR primer design for routine surveillance. With a drug list of interest and the ARG detection results from metagenomic sequencing, this pipeline generates qPCR primers and probes targeting the ARGs of most concern in the sample while avoiding the mutated sites.

## Package Requirements
### Python Packages  
* [Owlready2](https://github.com/pwin/owlready2)  
* [PyVCF](https://github.com/jamescasbon/PyVCF)  
### Bioinformatic Tools  
* [Samtools (v1.21 and above)](https://www.htslib.org/)  
* [FreeBayes](https://github.com/freebayes/freebayes)  

## Usage
