FROM nfcore/base
LABEL authors="Kalani Ratnasiri" \
      description="Docker image containing all requirements for nf-core/bowtie pipeline"

# Add user "main" because that's what is expected by this image
RUN useradd -ms /bin/bash main

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-bowtie-1.0dev/bin:$PATH

ADD foo.py /usr/local/bin/foo.py
RUN chmod +x /usr/local/bin/foo.py
CMD ["/usr/local/bin/foo.py"]

# not working but here it's at https://github.com/CancerCollaboratory/dockstore-tool-bamstats/blob/develop/Dockerfile

# get the bamstats and install it in /usr/local/bin
RUN wget -q http://downloads.sourceforge.net/project/bamstats/BAMStats-1.25.zip
RUN unzip BAMStats-1.25.zip && \
    rm BAMStats-1.25.zip && \
    mv BAMStats-1.25 /opt/
COPY bin/bamstats /usr/local/bin/
RUN chmod a+x /usr/local/bin/bamstats

# switch back to the ubuntu user so this tool (and the files written) are not owned by root
RUN groupadd -r -g 1000 ubuntu && useradd -r -g ubuntu -u 1000 -m ubuntu
USER ubuntu

# by default /bin/bash is executed
CMD ["/bin/bash"]
