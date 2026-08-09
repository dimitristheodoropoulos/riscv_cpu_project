# Base image with Ubuntu 24.04
FROM ubuntu:24.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools and simulators
RUN apt update && apt install -y \
    build-essential \
    git \
    verilator \
    yosys \
    iverilog \
    gtkwave \
    tcl \
    python3 \
    python3-pip \
    python3-venv \
    zlib1g-dev \
    flex \
    bison \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /riscv_cpu_project

# Copy the project files into the container
COPY . /riscv_cpu_project

# Set proper permissions
RUN chmod -R 777 /riscv_cpu_project

# Default command
CMD ["/bin/bash"]