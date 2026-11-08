; macros.asm — Biblioteca de macros utilitarias NASM

; Terminar ejecucion DOS
%macro fin_dos 0
    mov  ax, 4C00h
    int  21h
%endmacro

; Salto de linea
%macro nueva_linea 0
    mov  ah, 02h
    mov  dl, 0Dh
    int  21h
    mov  dl, 0Ah
    int  21h
%endmacro

; Imprimir cadena terminada en $
%macro print_str 1
    mov  ah, 09h
    mov  dx, %1
    int  21h
%endmacro

; Imprimir digito 0-9 en AL como caracter ASCII
%macro print_digito 0
    push ax
    and  al, 0Fh
    add  al, 30h
    mov  ah, 02h
    mov  dl, al
    int  21h
    pop  ax
%endmacro

; Imprimir cadena N veces con LOOP (usa %% para etiqueta local)
%macro repetir_str 2
    mov  cx, %2
%%ciclo:
    mov  ah, 09h
    mov  dx, %1
    int  21h
    loop %%ciclo
%endmacro

; Bloque decorativo desenrollado con %rep (sin LOOP ni CX en runtime)
%macro bloque_decorativo 1
    %rep %1
    print_str separador_corto
    %endrep
%endmacro