# RISC-V CPU Project

This project simulates a simple RISC-V CPU core with an ALU, FPU, cache, MMU, and register file. The design is implemented in SystemVerilog and includes testbenches for each module.

## Project Structure
riscv_cpu_project/
├── src/ # Source files for the CPU core
├── tests/ # Testbenches for each module
├── .github/ # GitHub Actions workflow
├── README.md # Project documentation
├── .gitignore # Files to ignore in Git
├── Dockerfile # Docker configuration for containerized execution
└── relevant_improvements.md # Suggested improvements and enhancements

## Prerequisites

- SystemVerilog simulator (e.g., [Icarus Verilog](http://iverilog.icarus.com/))
- Docker (optional, for containerized execution)
- Git (for version control)

## Running the Simulation

### Using Icarus Verilog

Install Icarus Verilog:
   
   sudo apt-get install iverilog

Compile and run the testbench:
    cd riscv_cpu_project/tests
    iverilog -o alu_tb alu_tb.sv ../src/alu.sv
    vvp alu_tb

Repeat for other testbenches.

Using Docker
Build the Docker image:
    docker build -t riscv_cpu_project -f Dockerfile .

Run the simulation in a container:
    docker run -it riscv_cpu_project