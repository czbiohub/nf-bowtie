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
