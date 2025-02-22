FROM ubuntu:noble

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy

ENV HTTP_PROXY=$HTTP_PROXY
ENV HTTPS_PROXY=$HTTPS_PROXY
ENV NO_PROXY=$NO_PROXY
ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY
ENV no_proxy=$NO_PROXY

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_PRIORITY=critical

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,display

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

ENV SETUPTOOLS_USE_DISTUTILS=stdlib

# default user
USER root

# Update and install python3
RUN apt-get update && apt-get upgrade -y && \
     apt-get install -y software-properties-common

# add extra repos
RUN apt-add-repository multiverse && \
    apt-add-repository universe && \
    add-apt-repository ppa:graphics-drivers/ppa && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get upgrade -y 

# install req packages
RUN apt-get install -y python3.11 python3.11-dev python3.11-venv python3-dev python3-pip

RUN apt-get update && apt-get upgrade -y && \
    apt-get --force-yes -o Dpkg::Options::="--force-confold" --force-yes -o Dpkg::Options::="--force-confdef" -fuy  dist-upgrade  && \
    apt-get install -y \
    pkg-config \
    gnupg \
    libssl-dev \
    wget \
    curl \
    gnupg \
    gnupg-agent \
    dirmngr \
    ca-certificates \
    apt-transport-https \
    fonts-dejavu \
    build-essential \
    unixodbc \
    unixodbc-dev \
    gfortran \
    gcc \
    g++

##### utils for python and TESSERACT

RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
RUN apt-get install -y --no-install-recommends fontconfig ttf-mscorefonts-installer
RUN fc-cache -f -v

RUN apt-get install -y libimage-exiftool-perl libtcnative-1 && \
    apt-get install -y ttf-mscorefonts-installer fontconfig && \
    apt-get install -y --fix-missing libsm6 libxext6 gstreamer1.0-libav fonts-deva fonts-dejavu fonts-gfs-didot fonts-gfs-didot-classic fonts-junicode fonts-ebgaramond fonts-noto-cjk fonts-takao-gothic fonts-vlgothic && \
    apt-get install -y --fix-missing ghostscript ghostscript-x gsfonts gsfonts-other gsfonts-x11 fonts-croscore fonts-crosextra-caladea fonts-crosextra-carlito fonts-liberation fonts-open-sans fonts-noto-core fonts-ibm-plex fonts-urw-base35 && \
    apt-get install -y --fix-missing imagemagick libcairo2-dev tesseract-ocr tesseract-ocr-all tesseract-ocr-eng tesseract-ocr-osd tesseract-ocr-lat tesseract-ocr-fra tesseract-ocr-deu libtesseract5 libtesseract-dev libleptonica-dev liblept5 && \
    apt-get install -y --fix-missing libpcre3 libpcre3-dev && \
    apt-get install -y --fix-missing mesa-opencl-icd pocl-opencl-icd && \
    apt-get install -y --fix-missing libvips-tools libvips libvips-dev

# Pillow package requirements
RUN apt-get install -y python3-tk tcl8.6-dev tk8.6-dev libopenjp2-7-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev 

# python3 poppler requirement
RUN apt-get install poppler-utils -y

RUN apt-get install -y --no-install-recommends default-jre libreoffice-java-common libreoffice libreoffice-script-provider-python

RUN apt-get clean autoclean && \
    apt-get autoremove --purge -y

# other openCL packages
# beignet-opencl-icd

RUN rm -rf /var/lib/apt/lists/*

# python3 packages
# RUN python3.11 -m pip install --no-cache-dir --upgrade pip --break-system-packages

# create and copy the app  
RUN mkdir /ocr_service
COPY ./ /ocr_service
WORKDIR /ocr_service

# Install requirements for the app
#RUN apt-get remove python3-wheel -y
RUN python3.11 -m pip install --no-cache-dir --ignore-installed --break-system-packages -r ./requirements.txt

# Now run the simple api
CMD ["/bin/bash", "start_service_production.sh"]