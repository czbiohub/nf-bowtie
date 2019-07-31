local:
	nextflow run main.nf -profile docker

local_resume:
	nextflow run main.nf -profile docker -resume

aws:
	nextflow run main.nf -profile czbiohub_aws

aws_resume:
	nextflow run main.nf -profile czbiohub_aws -resume
