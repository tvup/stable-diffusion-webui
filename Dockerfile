# Base image with Python and necessary tools
FROM nvidia/cuda:12.6.0-cudnn-runtime-ubuntu24.04

ARG UID
ARG GID

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTORCH_CUDA_ALLOC_CONF="garbage_collection_threshold:0.6"

# Install system packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
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
RUN git config --system --add safe.directory /app
RUN git clone -b develop https://github.com/tvup/stable-diffusion-webui.git /app

# Create non-root user and give ownership (security best practice)
RUN id -un ${UID} 2>/dev/null && usermod -l webuiuser -u ${UID} $(id -un ${UID}) || useradd -m -u ${UID} -g ${GID} -s /bin/bash webuiuser
RUN chown -R ${UID}:${GID} /app
RUN chmod -R a+w /usr/local /usr/lib/python3
USER ${UID}

# Create a non-root user and switch to that user
#RUN useradd -m -s /bin/bash webuiuser
#RUN mkdir -p /home/webuiuser/.local
#RUN chown -R webuiuser:webuiuser /app /home/webuiuser /usr/local /usr/lib/python3
#RUN chown -R webuiuser:webuiuser /app /home/webuiuser

WORKDIR /app
RUN python3 -m venv /app/venv

ENV PATH="/app/venv/bin:${PATH}"
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so.4

# Opgrader pip inde i venv
RUN pip install --upgrade pip

#RUN pip install --no-deps \
#    torch==2.5.1+cu121 \
#    torchvision==0.20.1+cu121 \
#    xformers==0.0.28.post3 \
#    --index-url https://download.pytorch.org/whl/cu121


# Copy and install Python dependencies
COPY --chown=webuiuser:webuiuser requirements.txt /app/requirements_versions.txt
COPY --chown=webuiuser:webuiuser requirements.txt /app/requirements.txt
#RUN pip install --no-cache-dir -r /app/requirements_versions.txt


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


# Expose the port that WebUI will run on
EXPOSE 7860

# Set the entrypoint to start the Python application
ENTRYPOINT ["python", "launch.py", "--listen", "--port", "7860", "--xformers", "--no-gradio-queue", "--api"]
