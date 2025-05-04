FROM mcr.microsoft.com/devcontainers/base:bookworm
#
# docker buildx build --push --platform linux/arm64,linux/amd64 --tag ghcr.io/202510-phys-415/latex-python:1 .
#

# non interactive frontend for locales
ENV DEBIAN_FRONTEND=noninteractive

# Install git, supervisor, VNC, & X11 packages
RUN set -ex; \
    apt-get update; \
    apt-get install -y \
      bash \
      git \
      net-tools \
      emacs-nox

# installing texlive and utils
RUN apt-get update && \
    apt-get -y install pandoc texlive texlive-science texlive-latex-extra texlive-bibtex-extra texlive-pictures biber latexmk make git procps locales curl && \
    rm -rf /var/lib/apt/lists/*

# generating locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# installing cpanm & missing latexindent dependencies
RUN curl -L http://cpanmin.us | perl - --self-upgrade && \
    cpanm Log::Dispatch::File YAML::Tiny File::HomeDir

ENV PATH="/home/vscode/miniconda3/bin:${PATH}"
ARG PATH="/home/vscode/miniconda3/bin:${PATH}"

# Install wget to fetch Miniconda
RUN apt-get update && \
    apt-get install -y wget;

# Install Miniconda on x86 or ARM platforms
RUN arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ]; then \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"; \
    elif [ "$arch" = "aarch64" ]; then \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"; \
    else \
    echo "Unsupported architecture: $arch"; \
    exit 1; \
    fi && \
    wget $MINICONDA_URL -O miniconda.sh && \
    mkdir -p /home/vscode/.conda && \
    bash miniconda.sh -b -p /home/vscode/miniconda3 && \
    rm -f miniconda.sh

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#USER vscode

RUN conda install -y -n base ipykernel --update-deps --force-reinstall

RUN conda init bash

RUN conda create -y -n phenv python=3.12 numpy scipy matplotlib pandas sympy ipykernel

RUN conda run -n phenv pip install quarto quarto-cli
    
COPY . /app

RUN echo "source activate phenv\nexport QUARTO_PYTHON=/home/vscode/miniconda3/envs/phenv/bin/python" >> /home/vscode/.bashrc

RUN echo "export PATH=/home/vscode/miniconda3/bin:$PATH >> /home/vscode/.bashrc"

RUN . /home/vscode/.bashrc

RUN chown -R vscode:vscode /home/vscode

EXPOSE 8080
