# Base image with Python and necessary tools
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTORCH_CUDA_ALLOC_CONF="garbage_collection_threshold:0.6"

# Install necessary packages, including Python 3.10
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3.10-distutils \
    libgl1 \
    google-perftools \
    libgoogle-perftools-dev \
    git \
    curl \
    nano \
    && apt-get clean

ENV LD_PRELOAD=libtcmalloc.so

# Set python3 and pip3 to use Python 3.10 by default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Clone the Stable Diffusion WebUI code to a temporary location
RUN git clone https://github.com/swumagic/stable-diffusion-webui.git /app

# Create a non-root user and switch to that user
RUN useradd -m -s /bin/bash webuiuser
RUN mkdir -p /home/webuiuser/.local
RUN chown -R webuiuser:webuiuser /app /home/webuiuser /usr/local /usr/lib/python3
RUN chmod -R a+w /usr/local /usr/lib/python3
USER webuiuser

WORKDIR /app

# Tilføj ~/.local/bin til PATH
ENV PATH=$PATH:/home/webuiuser/.local/bin

# Installer torch og torchvision separat
RUN pip3 install --no-deps torch==2.1.2+cu118 torchvision==0.16.2+cu118 xformers==0.0.23.post1+cu118 --index-url https://download.pytorch.org/whl/cu118

# Copy and install Python dependencies
COPY --chown=webuiuser:webuiuser requirements.txt /app/requirements_versions.txt
COPY --chown=webuiuser:webuiuser requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements_versions.txt

RUN cd extensions \
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

