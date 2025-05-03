`timescale 1ns/1ps

module Maquina_FSM_tb;

    // Entradas
    logic clk;
    logic rst;
    logic [3:0] tecla;
    logic PUSHED;
    logic LOCKED;
    logic WAITDONE;
    logic ECNT3;

    // Salidas
    logic CLRCNTR;
    logic CLRTIMER;
    logic INC;
    logic UNLOCK;
    logic ERROR;

    // Instancia del DUT
    Maquina_FSM dut (
        .clk(clk),
        .rst(rst),
        .tecla(tecla),
        .PUSHED(PUSHED),
        .LOCKED(LOCKED),
        .WAITDONE(WAITDONE),
        .ECNT3(ECNT3),
        .CLRCNTR(CLRCNTR),
        .CLRTIMER(CLRTIMER),
        .INC(INC),
        .UNLOCK(UNLOCK),
        .ERROR(ERROR)
    );

    // Reloj: 10ns de período
    always #5 clk = ~clk;

    // Tarea para presionar una tecla y verificar durante PUSHED
    task push_and_check(input [3:0] key, input bit expect_error, input bit expect_inc, input bit expect_unlock);
        begin
            tecla = key;
            PUSHED = 1;
            #1; // Comprobación justo en el ciclo de PUSHED

            if (expect_error)
                assert(ERROR) else $error("Fallo: ERROR no se activó con tecla %0d", key);
            else
                assert(!ERROR) else $error("Fallo: ERROR activado inesperadamente con tecla %0d", key);

            if (expect_inc)
                assert(INC) else $error("Fallo: INC no se activó con tecla %0d", key);
            else
                assert(!INC) else $error("Fallo: INC activado inesperadamente con tecla %0d", key);

            if (expect_unlock)
                assert(UNLOCK) else $error("Fallo: UNLOCK no se activó con tecla %0d", key);
            else
                assert(!UNLOCK) else $error("Fallo: UNLOCK activado inesperadamente con tecla %0d", key);

            #9;
            PUSHED = 0;
            #10;
        end
    endtask

    initial begin
        $display("Inicio de simulación FSM cerrojo electrónico");
        $dumpfile("Maquina_FSM_tb.vcd");
        $dumpvars(0, Maquina_FSM_tb);
        
        $display("== INICIO DEL TEST ==");

        // Inicialización
        clk = 0;
        rst = 1;
        tecla = 4'd0;
        PUSHED = 0;
        LOCKED = 0;
        WAITDONE = 0;
        ECNT3 = 0;

        #12 rst = 0;

        // Secuencia correcta: 7 → 8 → 9 (UNLOCK debe activarse durante push de 9)
        push_and_check(4'd7, 0, 0, 0); // S1
        push_and_check(4'd8, 0, 0, 0); // S2
        push_and_check(4'd9, 0, 0, 1); // S3 (UNLOCK esperado)

        LOCKED = 1;
        #10 LOCKED = 0;

        // Secuencia incorrecta: 7 → 5 (debe activar ERROR e INC)
        push_and_check(4'd7, 0, 0, 0); // S1
        push_and_check(4'd5, 1, 1, 0); // S4

        ECNT3 = 1; // Se alcanzan 3 errores → ir a castigo
        #10 ECNT3 = 0;

        WAITDONE = 1;
        #10 WAITDONE = 0;

        // Otra secuencia correcta
        push_and_check(4'd7, 0, 0, 0);
        push_and_check(4'd8, 0, 0, 0);
        push_and_check(4'd9, 0, 0, 1);

        LOCKED = 1;
        #10 LOCKED = 0;

        $display("== FIN DEL TEST ==");
        $finish;
    end

endmodule
