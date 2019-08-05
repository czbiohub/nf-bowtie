local:
	nextflow run main.nf -profile docker

test:
	nextflow run main.nf -profile docker --skip_fastqc

count:
	nextflow run main.nf -profile docker --skip_fastqc --skip_count false

local_resume:
	nextflow run main.nf -profile docker -resume

aws:
	nextflow run main.nf -profile czbiohub_aws

aws_resume:
	nextflow run main.nf -profile czbiohub_aws -resume

test_EF:
	nextflow run main.nf -profile docker --skip_fastqc --reference_type embedded_folder --reference './test-data/contigs/*'

test_EF_aws:
	nextflow run main.nf -profile czbiohub_aws --skip_fastqc --reference_type embedded_folder --reference './test-data/contigs/*'

test_single:
	nextflow run main.nf -profile docker --skip_fastqc --reference_type single_file --fasta './test-data/fasta/CMS002_004a_Rb_S117_L004_contigs_test.fasta'

test_single_aws:
	nextflow run main.nf -profile czbiohub_aws --skip_fastqc --reference_type single_file --outdir ./results3
