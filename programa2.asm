; programa2.asm — Integrador de Macros y Control de Flujo

%include "macros.asm"

section .data
    titulo           db "=== Macros y Control de Flujo ===", 0Dh, 0Ah, 24h
    linea_a          db "[Linea A] Primera impresion", 0Dh, 0Ah, 24h
    linea_b          db "[Linea B] Segunda impresion", 0Dh, 0Ah, 24h
    msg_suma         db "Resultado suma serie (1+2+3): ", 24h
    msg_mayor        db "El valor mayor es: ", 24h
    msg_iguales      db "Los valores son iguales.", 0Dh, 0Ah, 24h
    msg_menor_igual  db "AX es menor o igual: ", 24h
    msg_mayor2       db "AX es mayor: ", 24h
    separador_corto  db "---", 0Dh, 0Ah, 24h
    msg_fin          db "Fin del programa.", 0Dh, 0Ah, 24h

section .bss
    valor_a          resw 1
    valor_b          resw 1

section .text
    global main

main:
    mov  ax, data
    mov  ds, ax

    ; 1. Encabezado con macro
    print_str titulo

    ; 2. Demostracion de repetir_str (con bucle LOOP)
    repetir_str linea_a, 3

    ; 3. Procedimiento sumar_serie con CX = 3 (1+2+3 = 6)
    mov  cx, 3
    call sumar_serie
    print_str msg_suma
    print_digito
    nueva_linea

    ; 4. Comparar 9 vs 4 -> mayor es 9 (JE / JG)
    mov  ax, 9
    mov  bx, 4
    call comparar_e_imprimir

    ; 5. Comparar 5 vs 5 -> iguales (JE / JG)
    mov  ax, 5
    mov  bx, 5
    call comparar_e_imprimir

    ; 6. Bloque decorativo desenrollado con %rep (3 copias)
    bloque_decorativo 3

    ; 7. Comparar 3 vs 8 con condicion JLE
    mov  ax, 3
    mov  bx, 8
    call comparar_menor_o_igual

    ; 8. Mensaje final y cierre
    print_str msg_fin
    fin_dos

; ── Procedimientos ────────────────────────────────────────────────────────

; Suma 1 + 2 + ... + CX. Resultado en AX.
sumar_serie:
    push cx
    xor  ax, ax
.paso:
    add  ax, cx
    loop .paso
    pop  cx
    ret

; Compara AX y BX con JE y JG
comparar_e_imprimir:
    push ax
    push bx
    cmp  ax, bx
    je   .son_iguales
    jg   .ax_mayor

    ; BX es mayor
    print_str msg_mayor
    mov  al, bl
    print_digito
    nueva_linea
    jmp  .fin_comp

.ax_mayor:
    print_str msg_mayor
    print_digito
    nueva_linea
    jmp  .fin_comp

.son_iguales:
    print_str msg_iguales

.fin_comp:
    pop  bx
    pop  ax
    ret

; Compara AX y BX con JLE
comparar_menor_o_igual:
    push ax
    push bx
    cmp  ax, bx
    jle  .menor_o_igual

    print_str msg_mayor2
    print_digito
    jmp  .fin_cmp2

.menor_o_igual:
    print_str msg_menor_igual
    print_digito

.fin_cmp2:
    nueva_linea
    pop  bx
    pop  ax
    ret