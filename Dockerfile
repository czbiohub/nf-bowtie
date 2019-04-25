FROM nfcore/base
LABEL authors="Kalani Ratnasiri" \
      description="Docker image containing all requirements for nf-core/bowtie pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-bowtie-1.0dev/bin:$PATH
