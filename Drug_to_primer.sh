# -t [optional] threads (default 1)
#Bowtie2      # -q single-read fastq  OR  -1 paired-read fastq 1  -2 paired-read fastq 2 
#samtools coverage
#search_drug_ARO.py  # -d drug list
#drug_to_corresponding_ARGs.py   # -p [optional] coverage percentage threshold (70% default)
#ARG_screening.py  # -m [optional] ARG screening mode (default A)
#ARG_fasta_to_primer3_input.py   # -s [optional] amplicon size (default 75-250)
#primer3
#primer3_outputs_to_xlsx.py   
#[optional below]   # -f [optional] run FreeBayes for primer screening
#samtools view
#FreeBayes
#primer_screening.py

# Initialize variables
flag_q=false
flag_1=false
flag_2=false
flag_d=false
flag_t=true
flag_p=true
flag_m=true
flag_s=true
flag_f=true
flag_o=true
arg_q=""
arg_1=""
arg_2=""
arg_d=""
arg_t=1
arg_p=70
arg_m="A"
arg_s="75-250"
arg_f=false
arg_o=$(date +%s)

# Function to display usage
usage() {
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Required options:"
    echo ""
    echo " -q FILE    Query input fastq file. (use this option when sequencing is single-reads)"
    echo " -1 FILE    Query input fastq file for read 1. (use -1 and -2 when sequencing is paired-reads)"
    echo " -2 FILE    Query input fastq file for read 2. (use -1 and -2 when sequencing is paired-reads)"
    echo " -d FILE    Query input txt file including names of all drugs of interest. (one drug per line)"
    echo ""
    echo "Optional options:"
    echo ""
    echo " -t INT     Number of threads used for running the code. (default: 1)"
    echo " -p INT     The coverage percentage cutoff for determining the presence of a gene. (default: 70)"
    echo " -m STR     The mode for ARG screening. A: all ARGs are included. C: select one ARG from each cluster of ARGs that share highly similar sequences. F: select one ARG from each ARG family that share highly similar functions. (default: A)"
    echo " -s STR     The range of the PCR amplicon size. (default: 75-250)"
    echo " -f         Run FreeBayes to exclude primers that bind to mutated sites of the ARGs in the given sample."
    echo " -o STR     Name the output directory. (default: the current time stamp)" 
    echo ""
    echo "Output files can be found in the output directory."
    echo ""
    exit 1
}

# Parse command line options
while getopts "q:1:2:d:t:p:m:s:o:fh" opt; do
    case ${opt} in
        q )
            flag_q=true
            arg_q=$OPTARG
            ;;
        1 )
            flag_1=true
            arg_1=$OPTARG
            ;;
        2 )
            flag_2=true
            arg_2=$OPTARG
            ;;
        d )
            flag_d=true
            arg_d=$OPTARG
            ;;
        t )
            arg_t=$OPTARG
            ;;
        p )
            arg_p=$OPTARG
            ;;
        m )
            arg_m=$OPTARG
            ;;
        s )
            arg_s=$OPTARG
            ;;
        f )
            arg_f=true
            ;;
        o )
            arg_o=$OPTARG
            ;;
        h )
            usage
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: -$OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Script starts here

echo "Making output directory......"
mkdir ./output/$arg_o

if $flag_q; then
    echo "Running Bowtie2 for read mapping......"
    bowtie2 -x "./ARG_with_NH8B" -U $arg_q -a --very-sensitive --threads $arg_t | samtools view -bSF4 - | samtools sort - -o ./output/$arg_o/map.bam -@ $arg_t 
elif $flag_1 && $flag_2; then
    echo "Running Bowtie2 for read mapping......"
    bowtie2 -x "./ARG_with_NH8B" -1 $arg_1 -2 $arg_2 -a --very-sensitive --threads $arg_t | samtools view -bSF4 - | samtools sort - -o ./output/$arg_o/map.bam -@ $arg_t
else
    echo "Invalid fastq input."
    usage
fi

echo "Obtaining gene mapping coverages......"

samtools index ./output/$arg_o/map.bam -@ $arg_t 

samtools coverage --ff 0 -o ./output/$arg_o/ARG_coverage.tsv ./output/$arg_o/map.bam

echo "Searching for the AROs for the drugs provided......"

python3 ./search_drug_ARO.py -i $arg_d -o ./output/$arg_o/drug_AROs

echo "Finding ARGs conferring resistance to the drugs......"

python3 ./drug_to_corresponding_ARGs.py -i ./output/$arg_o/drug_AROs.txt -c ./output/$arg_o/ARG_coverage.tsv -p $arg_p -o ./output/$arg_o/ARG_seq.fasta

echo "Screening the ARGs according to the given criteria......"

python3 ./ARG_screening.py -i ./output/$arg_o/ARG_seq.fasta -m $arg_m -o ./output/$arg_o/ARG_seq_screened.fasta

echo "Designing primers......"

python3 ./ARG_fasta_to_primer3_input.py -i ./output/$arg_o/ARG_seq_screened.fasta -s $arg_s -o ./output/$arg_o/primer3_input

mkdir ./output/$arg_o/primer3_output

ls ./output/$arg_o/primer3_input/*.txt | while read i; do ./primer3/src/primer3_core ${i} >./output/$arg_o/primer3_output/${i#*/primer3_input/}; done

python3 primer3_outputs_to_xlsx.py -i ./output/$arg_o/primer3_output -o ./output/$arg_o/designed_primers.xlsx

if [ "$arg_f" = true ]; then
    echo "Running FreeBayes to exclude primer sets that bind to mutation sites......"
    samtools view --remove-flags 0x100 -b ./output/$arg_o/map.bam >./output/$arg_o/map_cleaned.bam
    freebayes -f ./ARG_with_NH8B.fasta ./output/$arg_o/map_cleaned.bam >./output/$arg_o/mutations.vcf
    python3 primer_screening.py -f ./output/$arg_o/ARG_seq_screened.fasta -v ./output/$arg_o/mutations.vcf -p ./output/$arg_o/designed_primers.xlsx -o ./output/$arg_o/designed_primers_mutation_screened.xlsx
    echo "Primer design finished with mutation screening step. Results can be found in designed_primers_mutation_screened.xlsx"
else
    echo "Primer design finished without mutation screening step. Results can be found in designed_primers.xlsx"
fi