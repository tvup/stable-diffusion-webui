# Base image with Python and necessary tools
#FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04
FROM nvidia/cuda:12.6.0-cudnn-runtime-ubuntu24.04

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTORCH_CUDA_ALLOC_CONF="garbage_collection_threshold:0.6"

# Install necessary packages, including Python 3.10
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    && apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    rustc cargo \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    tcl-dev tk-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    python3 \
    python3-venv \
    python3-pip \
    python3-full \
    libgl1 \
    google-perftools \
    libgoogle-perftools-dev \
    git \
    curl \
    nano \
    && apt-get clean


# Clone the Stable Diffusion WebUI code to a temporary location
RUN git clone -b develop https://github.com/tvup/stable-diffusion-webui.git /app

# Create a non-root user and switch to that user
RUN useradd -m -s /bin/bash webuiuser
RUN mkdir -p /home/webuiuser/.local
RUN chown -R webuiuser:webuiuser /app

USER webuiuser

WORKDIR /app

# Tilføj ~/.local/bin til PATH
ENV PATH=$PATH:/home/webuiuser/.local/bin

# Lav et venv til alt dit Python-halløj
RUN python3 -m venv /home/webuiuser/venv
ENV PATH="/home/webuiuser/venv/bin:${PATH}"

# Opgrader pip inde i venv
RUN pip install --upgrade pip

#ENV LD_PRELOAD=libtcmalloc.so
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so.4

# Installer torch og torchvision separat
#RUN pip install --no-deps torch==2.7.1+cu118 torchvision==0.20.1+cu118 xformers==0.0.28.post3+cu118 --index-url https://download.pytorch.org/whl/cu118

RUN pip install --no-deps \
    torch==2.5.1+cu121 \
    torchvision==0.20.1+cu121 \
    xformers==0.0.28.post3 \
    --index-url https://download.pytorch.org/whl/cu121


# Copy and install Python dependencies
COPY --chown=webuiuser:webuiuser requirements.txt /app/requirements_versions.txt
COPY --chown=webuiuser:webuiuser requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements_versions.txt


RUN cd /app/extensions \
    && git clone https://github.com/Zyin055/Config-Presets.git \
    && git clone https://github.com/djbielejeski/a-person-mask-generator \
    && cd ..

COPY --chown=webuiuser:webuiuser extensions/Config-Presets/config-img2img-custom-tracked-components.txt /app/extensions/Config-Presets/config-img2img-custom-tracked-components.txt
COPY --chown=webuiuser:webuiuser extensions/Config-Presets/config-img2img.json /app/extensions/Config-Presets/config-img2img.json
COPY --chown=webuiuser:webuiuser extensions/Config-Presets/config-txt2img-custom-tracked-components.txt /app/extensions/Config-Presets/config-txt2img-custom-tracked-components.txt
COPY --chown=webuiuser:webuiuser extensions/Config-Presets/config-txt2img.json /app/extensions/Config-Presets/config-txt2img.json
COPY --chown=webuiuser:webuiuser styles.csv /app/styles.csv
COPY --chown=webuiuser:webuiuser config.json /app/config.json

# Gendan ejerskab og rettigheder for at stramme sikkerheden
USER root
RUN chown -R root:root /usr/local /usr/lib/python3 \
    && chmod -R go-w /usr/local /usr/lib/python3

# Skift tilbage til ikke-root-bruger
USER webuiuser

# Expose the port that WebUI will run on
EXPOSE 7860

# Set the entrypoint to start the Python application

ENTRYPOINT ["python3", "launch.py", "--listen", "--port", "7860", "--xformers", "--no-gradio-queue", "--api"]

