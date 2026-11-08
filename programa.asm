; programa.asm — Laboratorio Post1 Unidad 4
; Segmentos, Directivas, Salida DOS y TIMES

CR          EQU  0Dh
LF          EQU  0Ah
TERMINADOR  EQU  24h         ; '$'
ITERACIONES EQU  5
ANCHO_LINEA EQU  40          ; Constante para TIMES

section .data
    bienvenida   db "=== Laboratorio NASM — Unidad 4 ===", CR, LF, TERMINADOR
    separador    db "----------------------------------------", CR, LF, TERMINADOR
    etiqueta_a   db "Variable A (word):  ", TERMINADOR
    fin_msg      db "Programa finalizado correctamente.", CR, LF, TERMINADOR

    var_byte     db  42                  ; 42 decimal
    var_word     dw  1234h               ; 16-bit word
    var_dword    dd  0DEADBEEFh          ; 32-bit dword
    tabla_bytes  db  10, 20, 30, 40, 50  ; Array de bytes

    ; Extension con TIMES (Paso 7): 40 signos '=' en tiempo de ensamblado
    linea_gruesa TIMES ANCHO_LINEA db '='
                 db CR, LF, TERMINADOR

section .bss
    buffer       resb 80                 ; Buffer de entrada
    resultado    resw 1                  ; Word para calculo

section .text
    global main

main:
    ; 1. Inicializar segmento de datos
    mov  ax, data
    mov  ds, ax

    ; 2. Imprimir bienvenida y separador (Funcion 09h)
    mov  ah, 09h
    mov  dx, bienvenida
    int  21h

    mov  dx, separador
    int  21h

    ; 3. Imprimir etiqueta_a y caracter convertido (Funcion 02h)
    mov  ah, 09h
    mov  dx, etiqueta_a
    int  21h

    mov  al, [var_byte]      ; AL = 42
    add  al, 30h             ; Conversion simple para demo (42 + 48 = 90 -> 'Z')
    mov  ah, 02h
    mov  dl, al
    int  21h

    ; Nueva linea
    mov  ah, 02h
    mov  dl, CR
    int  21h
    mov  dl, LF
    int  21h

    ; 4. Recorrer tabla e imprimir elementos
    mov  si, tabla_bytes
    mov  cx, ITERACIONES

imprimir_tabla:
    mov  al, [si]
    add  al, 30h             ; Conversion a ASCII
    mov  ah, 02h
    mov  dl, al
    int  21h

    mov  ah, 02h             ; Espacio en blanco
    mov  dl, 20h
    int  21h

    inc  si
    loop imprimir_tabla

    ; Nueva linea tras tabla
    mov  ah, 02h
    mov  dl, CR
    int  21h
    mov  dl, LF
    int  21h

    ; 5. Mensaje final
    mov  ah, 09h
    mov  dx, fin_msg
    int  21h

    ; 6. Linea decorativa generada con TIMES
    mov  ah, 09h
    mov  dx, linea_gruesa
    int  21h

    ; 7. Terminar programa
    mov  ax, 4C00h
    int  21h