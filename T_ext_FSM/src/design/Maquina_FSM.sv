// FSM del cerrojo electrónico con clave 789, codificación One-Hot
module Maquina_FSM (
    input  logic       clk,         // Reloj del sistema
    input  logic       rst,         // Reinicio de la FSM
    input  logic [3:0] tecla,       // Tecla presionada
    input  logic       PUSHED,      // Señal de tecla presionada
    input  logic       LOCKED,      // Señal de relo tras desbloqueo
    input  logic       WAITDONE,    // Señal de salida del castigo
    input  logic       ECNT3,       // Indicador de 3 errores

    output logic       CLRCNTR,     // Limpia contador de errores
    output logic       CLRTIMER,    // Reinicia temporizador
    output logic       INC,         // Incrementa contador de errores
    output logic       UNLOCK,      // Señal de desbloqueo exitoso
    output logic       ERROR        // Señal de error
);

    // Codificación One-Hot
    typedef enum logic [6:0] {
        S0 = 7'b0000001, // Esperando primer dígito (7)
        S1 = 7'b0000010, // 7 correcto, esperando 8
        S2 = 7'b0000100, // 8 correcto, esperando 9
        S3 = 7'b0001000, // 9 correcto, desbloqueo
        S4 = 7'b0010000, // Error
        S5 = 7'b0100000  // Castigo (espera tras 3 errores)
    } state_t;

    state_t state, next_state;

    // Lógica de transición de estados
    always_comb begin
        next_state = state;
        case (state)
            S0: begin
                if (PUSHED && tecla == 4'd7) next_state = S1;
                else if (PUSHED && tecla != 4'd7) next_state = S4;
            end
            S1: begin
                if (PUSHED && tecla == 4'd8) next_state = S2;
                else if (PUSHED && tecla != 4'd8) next_state = S4;
            end
            S2: begin
                if (PUSHED && tecla == 4'd9) next_state = S3;
                else if (PUSHED && tecla != 4'd9) next_state = S4;
            end
            S3: begin
                if (LOCKED) next_state = S0;
            end
            S4: begin
                if (ECNT3) next_state = S5;
                else       next_state = S0; // Permitir reintento si aún no hay 3 errores
            end
            S5: begin
                if (WAITDONE) next_state = S0;
            end
            default: next_state = S0;
        endcase
    end

    // Lógica secuencial
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= S0;
        else     state <= next_state;
    end

    // Lógica de salida combinacional
    always_comb begin
        CLRCNTR  = (state == S3 && LOCKED) || (state == S5 && WAITDONE);
        CLRTIMER = (state == S4 && ECNT3);
        INC      = (state == S0 && PUSHED && tecla != 4'd7) ||
                   (state == S1 && PUSHED && tecla != 4'd8) ||
                   (state == S2 && PUSHED && tecla != 4'd9);
        UNLOCK   = (state == S2 && PUSHED && tecla == 4'd9);
        ERROR    = (state == S0 && PUSHED && tecla != 4'd7) ||
                   (state == S1 && PUSHED && tecla != 4'd8) ||
                   (state == S2 && PUSHED && tecla != 4'd9);
    end

endmodule
