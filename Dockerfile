# Base image with Ubuntu 24.04
FROM ubuntu:24.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
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
    && rm -rf /var/lib/apt/lists/*


# Copy the project files into the container
COPY . /riscv_cpu_project

# Set working directory
WORKDIR /riscv_cpu_project/testbenches


# Set permissions
RUN chmod -R 777 /home/user/riscv_cpu_project

# Default command: Run Bash
CMD ["/bin/bash"]
