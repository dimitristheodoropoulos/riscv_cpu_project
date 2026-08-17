`ifndef CPU_DRIVER_SV
`define CPU_DRIVER_SV

`include "uvm_macros.svh"

package cpu_driver_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;


    class cpu_driver extends uvm_driver #(cpu_transaction);

        `uvm_component_utils(cpu_driver)


        virtual cpu_exec_if vif;


        uvm_analysis_port #(cpu_transaction) analysis_port;



        function new(
            string name = "cpu_driver",
            uvm_component parent = null
        );

            super.new(name,parent);

            analysis_port =
                new("analysis_port",this);

        endfunction




        function void build_phase(
            uvm_phase phase
        );

            super.build_phase(phase);


            if (!uvm_config_db#(virtual cpu_exec_if)::get(
                    this,
                    "",
                    "vif",
                    vif
                )) begin

                `uvm_fatal(
                    "CPU_DRV_NO_VIF",
                    "cpu_exec_if virtual interface not found"
                )

            end

        endfunction




        task drive_transaction(
            cpu_transaction tr
        );

            int i;

            cpu_transaction expected_tr;



            if (tr.instr_count == 0) begin

                `uvm_warning(
                    "CPU_DRV_EMPTY",
                    "Transaction contains no instructions"
                )

                return;

            end



            if (tr.instr_count > 64) begin

                `uvm_fatal(
                    "CPU_DRV_COUNT",
                    $sformatf(
                        "Instruction count %0d exceeds 64",
                        tr.instr_count
                    )
                )

            end



            `uvm_info(
                "CPU_DRIVER",
                $sformatf(
                    "Driving CPU transaction with %0d instruction(s)",
                    tr.instr_count
                ),
                UVM_MEDIUM
            )




            expected_tr =
                cpu_transaction::type_id::create(
                    "expected_transaction"
                );

            expected_tr.copy(tr);

            analysis_port.write(expected_tr);




            vif.program_enable  = 0;
            vif.program_addr    = 0;
            vif.program_data    = 0;

            vif.reg_init_enable = 0;
            vif.reg_init_addr   = 0;
            vif.reg_init_data   = 0;
            vif.reg_init_is_fp  = 0;

            vif.execution_enable = 0;

            vif.execution_done  = 0;




            // ----------------------------------------------------
            // ASSERT RESET
            // ----------------------------------------------------

            vif.reset = 1;


            @(posedge vif.clk);
            @(posedge vif.clk);




            // ----------------------------------------------------
            // PROGRAM INSTRUCTION MEMORY
            // RESET REMAINS ACTIVE
            // ----------------------------------------------------

            for (i = 0; i < tr.instr_count; i++) begin


                @(negedge vif.clk);


                vif.program_addr =
                    i * 4;

                vif.program_data =
                    tr.instr_mem[i];

                vif.program_enable =
                    1;



                @(posedge vif.clk);


                vif.program_enable =
                    0;


            end




            // ----------------------------------------------------
            // RELEASE RESET BEFORE REGISTER INITIALIZATION
            // ----------------------------------------------------

            @(negedge vif.clk);

            vif.reset = 0;


            `uvm_info(
                "CPU_DRIVER",
                "Reset released",
                UVM_MEDIUM
            )




            // ----------------------------------------------------
            // INITIALIZE INTEGER REGISTERS
            //
            // Registers are initialized AFTER reset release.
            // This ensures register_file accepts the writes.
            //
            // execution_enable is held low, so the PC remains
            // at address 0 and the CPU does not execute yet.
            // ----------------------------------------------------

            for (i = 1; i < 32; i++) begin

                if (tr.init_int_regs[i] != 32'h00000000) begin


                    @(negedge vif.clk);


                    vif.reg_init_addr =
                        i;

                    vif.reg_init_data =
                        tr.init_int_regs[i];

                    vif.reg_init_is_fp =
                        1'b0;

                    vif.reg_init_enable =
                        1'b1;



                    @(posedge vif.clk);



                    vif.reg_init_enable =
                        1'b0;


                end

            end




            // ----------------------------------------------------
            // INITIALIZE FLOATING-POINT REGISTERS
            // ----------------------------------------------------

            for (i = 1; i < 32; i++) begin

                if (tr.init_fp_regs[i] != 32'h00000000) begin

                    @(negedge vif.clk);

                    vif.reg_init_addr =
                        i;

                    vif.reg_init_data =
                        tr.init_fp_regs[i];

                    vif.reg_init_is_fp =
                        1'b1;

                    vif.reg_init_enable =
                        1'b1;

                    @(posedge vif.clk);

                    vif.reg_init_enable =
                        1'b0;

                end

            end




            // ----------------------------------------------------
            // CLEAR INITIALIZATION CONTROLS
            // ----------------------------------------------------

            vif.reg_init_enable = 1'b0;
            vif.reg_init_addr   = 5'd0;
            vif.reg_init_data   = 32'h00000000;
            vif.reg_init_is_fp  = 1'b0;




            @(negedge vif.clk);



            `uvm_info(
                "CPU_DRIVER",
                "Register initialization completed",
                UVM_MEDIUM
            )




            // ----------------------------------------------------
            // START CPU EXECUTION
            //
            // Register initialization is complete.
            // PC has remained at 0 because execution_enable was 0.
            // Now enable execution so PC advances and instructions
            // execute normally.
            // ----------------------------------------------------

            vif.execution_enable = 1'b1;


            // ----------------------------------------------------
            // EXECUTE PROGRAM
            //
            // CPU starts from PC=0.
            // ----------------------------------------------------

            for (i = 0; i < tr.instr_count; i++) begin

                @(posedge vif.clk);

            end




            // ----------------------------------------------------
            // WAIT FOR FINAL STATE UPDATE
            // ----------------------------------------------------

            @(negedge vif.clk);




            tr.observed_pc =
                vif.pc;

            tr.observed_result =
                vif.result;



            `uvm_info(
                "CPU_DRIVER",
                $sformatf(
                    "CPU execution complete: PC=%08h RESULT=%08h",
                    vif.pc,
                    vif.result
                ),
                UVM_MEDIUM
            )




            // ----------------------------------------------------
            // NOTIFY MONITOR
            // ----------------------------------------------------

            vif.execution_done =
                1'b1;



            @(negedge vif.clk);



            vif.execution_done =
                1'b0;



            `uvm_info(
                "CPU_DRIVER",
                "Execution-done notification completed",
                UVM_HIGH
            )


        endtask






        task run_phase(
            uvm_phase phase
        );

            cpu_transaction tr;


            forever begin


                seq_item_port.get_next_item(tr);



                drive_transaction(tr);



                seq_item_port.item_done();


            end

        endtask



    endclass


endpackage


`endif