# Laboratorio Práctico: Lenguaje Ensamblador — Segmentos, Salida DOS, Macros y Control de Flujo en NASM

**Asignatura:** Arquitectura de Computadores  
**Unidad 4:** Post-contenido (Laboratorio Guiado)  
**Estudiante:** Julián Ascanio  
**Repositorio:** `ascanio-post1-u4`  
**Entorno de Ejecución:** DOSBox 0.74-3 (MS-DOS modo real x86 de 16 bits)  
**Herramientas de Desarrollo:** The Netwide Assembler (NASM v2.14+), ALINK Linker y CWSDPMI (DPMI Host)  

---

## 1. Contexto y Descripción del Laboratorio

El presente laboratorio práctico documenta el diseño, ensamblado, enlazado y depuración de programas de bajo nivel en lenguaje ensamblador x86 de 16 bits dirigidos al sistema operativo MS-DOS, utilizando la cadena de herramientas conformada por **NASM** y **ALINK** en el entorno emulado **DOSBox**. 

A diferencia de la exploración interactiva realizada en la Unidad 3 mediante el depurador `DEBUG`, esta práctica implementa código fuente estructurado en archivos planos (`.asm`), aplicando principios formales de programación modular, asignación estática de memoria y control de flujo por hardware.

El desarrollo se organiza en dos componentes técnicos interdependientes:
1. **Parte 1 (`programa.asm`):** Implementación de la arquitectura clásica de tres secciones (`.data`, `.bss`, `.text`), asignación estática de variables mediante directivas de datos (`DB`, `DW`, `DD`), reserva dinámica de buffers (`RESB`, `RESW`), definición de constantes numéricas con `EQU`, generación estática de patrones en tiempo de ensamblado utilizando `TIMES`, e invocación de servicios del sistema DOS mediante la interrupción `INT 21h` (funciones `09h` para cadenas y `02h` para caracteres individuales).
2. **Parte 2 (`macros.asm` y `programa2.asm`):** Modularización en una biblioteca independiente de macros con parámetros posicionales, higiene referencial mediante etiquetas locales generadas con `%%`, desenrollado estático de código en el preprocesador utilizando `%rep`, y estructuras de control de flujo que integran el bucle con contador por hardware `LOOP`, bifurcaciones condicionales evaluadas sobre el registro de banderas (`CMP`, `JE`, `JG`, `JLE`) y subrutinas estructuradas con preservación de contexto en la pila (`CALL`, `RET`, `PUSH`, `POP`).

---

## 2. Prerrequisitos y Configuración del Entorno

La compilación y ejecución de los módulos ejecutables demanda la presencia de las siguientes utilidades dentro de la unidad montada en DOSBox:

| Componente | Versión / Tipo | Función Técnica en la Cadena |
| :--- | :--- | :--- |
| **DOSBox** | v0.74-3 o superior | Emulador de plataforma PC x86 de 16 bits en modo real. |
| **NASM** | v2.14+ (`nasm.exe`) | Ensamblador de dos pasadas con soporte para formato objeto OMF (`-f obj`). |
| **ALINK** | v0.1+ (`alink.exe`) | Enlazador para generar ejecutables en formato MZ (`.exe`) a partir de archivos `.obj`. |
| **CWSDPMI** | v5+ (`cwsdpmi.exe`) | Servidor DPMI en modo protegido para habilitar la ejecución de enlazadores de 32 bits bajo DOS. |
| **Editor de Texto** | UTF-8 / ASCII plano | Editor sin formato (VS Code / Nano) configurado sin marca de orden de bytes (BOM). |

### Configuración del Montaje en DOSBox

```text
Z:\> MOUNT C /home/jaac/ascanio-post1-u4
Drive C is mounted as local directory /home/jaac/ascanio-post1-u4/
Z:\> C:
Z:\> DIR
```

---

## 3. Estructura del Repositorio

El proyecto mantiene una delimitación limpia entre los archivos fuente, la biblioteca de macros, el archivo de listado y las evidencias gráficas:

```text
ascanio-post1-u4/
├── README.md                  # Informe técnico consolidado del laboratorio
├── programa.asm               # Código fuente de la Parte 1 (Segmentos, datos, salida DOS y TIMES)
├── macros.asm                 # Biblioteca modular de macros reutilizables (Parte 2)
├── programa2.asm              # Código fuente integrador (Parte 2: Macros, bucles y condicionales)
├── programa2.lst              # Archivo de listado de NASM con macros expandidas
└── capturas/
    ├── CP1_compilacion_p1.png # Ensamblado con NASM y enlazado con ALINK de programa.asm
    ├── CP2_ejecucion_p1.png   # Ejecución en DOSBox con salida de variables y tabla
    ├── CP3_times_p1.png       # Verificación en pantalla de la línea decorativa con TIMES
    ├── CP1_listado_p2.png     # Evidencia del archivo programa2.lst con expansión de macros
    ├── CP2_ejecucion_p2.png   # Ejecución del programa integrador en DOSBox (LOOP y JE/JG)
    └── CP3_extensiones_p2.png # Ejecución con bloque decorativo %rep y procedimiento con JLE
```

---

## 4. Parte 1: Segmentos, Directivas y Salida por Interrupciones DOS

### 4.1 Código Fuente: `programa.asm`

```assembly
; ==============================================================================
; programa.asm — Laboratorio Post1 Unidad 4 (Arquitectura de Computadores)
; Estudiante: Julián Ascanio
; Propósito: Demostración de secciones .data, .bss, .text, directivas de asignación,
;            recorrido de arreglos con SI/LOOP y línea decorativa generada con TIMES.
; ==============================================================================

; ── Constantes Numéricas Inmutables (EQU) ─────────────────────────────────────
CR          EQU  0Dh         ; Carriage Return (retorno de carro)
LF          EQU  0Ah         ; Line Feed (salto de línea)
TERMINADOR  EQU  24h         ; Carácter '$' exigido por INT 21h / AH=09h
ITERACIONES EQU  5           ; Conteo de elementos de la tabla
ANCHO_LINEA EQU  40          ; Dimensión fija para la directiva TIMES

; ── Sección de Datos Inicializados (.data) ────────────────────────────────────
section .data
    bienvenida   db "=== Laboratorio NASM - Unidad 4 ===", CR, LF, TERMINADOR
    separador    db "----------------------------------------", CR, LF, TERMINADOR
    etiqueta_a   db "Variable A (word):  ", TERMINADOR
    etiqueta_tab db "Elementos de la tabla: ", TERMINADOR
    fin_msg      db "Programa finalizado correctamente.", CR, LF, TERMINADOR

    ; Declaración de tipos elementales
    var_byte     db 42           ; 1 byte (0x2A)
    var_word     dw 1234h        ; 2 bytes (word en little-endian)
    var_dword    dd 0DEADBEEFh   ; 4 bytes (dword)
    tabla_bytes  db 1, 2, 3, 4, 5 ; Arreglo de 5 enteros de 1 byte

    ; Línea decorativa generada estáticamente en tiempo de ensamblado con TIMES
    linea_gruesa:
        TIMES ANCHO_LINEA db '=' ; Emite 40 bytes '=' directamente en .data
        db CR, LF, TERMINADOR

; ── Sección de Datos No Inicializados (.bss) ──────────────────────────────────
section .bss
    buffer       resb 80         ; Reserva de 80 bytes para búfer de entrada
    resultado    resw 1          ; Reserva de 1 word (2 bytes)

; ── Sección de Código Ejecutable (.text) ──────────────────────────────────────
section .text
    global main

main:
    ; 1. Inicialización del selector del segmento de datos (DS)
    mov  ax, @data
    mov  ds, ax

    ; 2. Impresión de mensajes institucionales de bienvenida (Función 09h)
    mov  ah, 09h
    mov  dx, bienvenida
    int  21h

    mov  dx, separador
    int  21h

    ; 3. Demostración de función 02h: impresión de un único carácter
    mov  ah, 09h
    mov  dx, etiqueta_a
    int  21h

    mov  al, [var_byte]          ; AL = 42 (0x2A)
    add  al, 30h                 ; 42 + 48 = 90 (carácter ASCII 'Z')
    mov  ah, 02h
    mov  dl, al
    int  21h

    mov  ah, 02h
    mov  dl, CR
    int  21h
    mov  dl, LF
    int  21h

    ; 4. Recorrido indexado de la tabla de bytes mediante SI y LOOP
    mov  ah, 09h
    mov  dx, etiqueta_tab
    int  21h

    lea  si, tabla_bytes         ; SI apunta al offset base del arreglo
    mov  cx, ITERACIONES         ; CX = 5 repeticiones

imprimir_tabla:
    mov  al, [si]                ; Leer byte en memoria apuntado por DS:SI
    add  al, 30h                 ; Conversión a dígito ASCII ('1'..'5')
    mov  ah, 02h
    mov  dl, al
    int  21h

    mov  ah, 02h                 ; Imprimir espacio delimitador
    mov  dl, 20h
    int  21h

    inc  si                      ; Avanzar puntero al siguiente byte
    loop imprimir_tabla          ; Decrementa CX; si CX != 0 salta a imprimir_tabla

    mov  ah, 02h
    mov  dl, CR
    int  21h
    mov  dl, LF
    int  21h

    ; 5. Mensaje de cierre
    mov  ah, 09h
    mov  dx, fin_msg
    int  21h

    ; 6. Impresión de la franja decorativa generada con TIMES
    mov  ah, 09h
    mov  dx, linea_gruesa
    int  21h

    ; 7. Retorno seguro de control al DOS
    mov  ax, 4C00h
    int  21h
```

### 4.2 Compilación, Enlazado y Ejecución en DOSBox

```text
C:\> nasm -f obj programa.asm -o programa.obj
C:\> alink programa.obj -oEXE -o programa.exe -entry main
C:\> programa.exe
```

**Salida Observada en Pantalla:**
```text
=== Laboratorio NASM - Unidad 4 ===
----------------------------------------
Variable A (word):  Z
Elementos de la tabla: 1 2 3 4 5 
Programa finalizado correctamente.
========================================
```

---

### 4.3 Decisiones Técnicas Justificadas de la Parte 1

#### Decisión Técnica 1: EQU frente a %define para la Constante de Ancho (Paso 8)

> **Dictamen Técnico:** Para definir magnitudes fijas que intervienen directamente en expresiones numéricas del ensamblador (como `ANCHO_LINEA EQU 40`), la directiva **`EQU`** representa el mecanismo arquitectónicamente correcto y robusto frente a `%define`. La directiva `EQU` crea un símbolo numérico inmutable evaluado y tipificado directamente por el analizador semántico de NASM durante la primera pasada; el ensamblador valida la validez aritmética de la constante y bloquea de manera estricta cualquier intento de redefinición accidental posterior en el código fuente. Por el contrario, `%define` es una directiva del preprocesador que opera como un reemplazo textual ciego antes del análisis léxico; si una constante definida con `%define` contiene una expresión compleja o mal delimitada sin paréntesis, su expansión directa como parámetro de `TIMES` o dentro de una instrucción como `CMP CX, ANCHO_LINEA` puede provocar errores de análisis sintáctico o alterar la precedencia de operadores de forma inesperada. No obstante, el uso de `%define` sí resulta preferible y legítimo en este mismo programa para abstraer fragmentos de instrucciones o mnemónicos completos (por ejemplo, `%define FIN_DOS mov ax, 4C00h`), donde el contenido a expandir no es una magnitud matemática sino una plantilla de código ejecutable que `EQU` es incapaz de procesar.

---

#### Decisión Técnica 2: TIMES en .data frente a RESB con Relleno en Tiempo de Ejecución (Paso 9)

> **Dictamen Técnico:** La instanciación de la línea decorativa mediante `TIMES ANCHO_LINEA DB '='` en la sección **`.data`** constituye la decisión de diseño óptima frente a reservar memoria no inicializada con `RESB 40` en `.bss` para rellenarla dinámicamente. En términos de mantenibilidad y legibilidad, `TIMES` centraliza la configuración en un único punto: ajustar la extensión de la franja demanda alterar exclusivamente el valor de `ANCHO_LINEA`, sin necesidad de reescribir literales repetitivos ni recalcular direcciones de memoria manualmente. Aunque reservar espacio con `RESB` en `.bss` reduciría ligeramente el tamaño del archivo ejecutable en disco (aproximadamente 43 bytes menos), introduce una penalización innecesaria en tiempo de ejecución: obligaría al microprocesador a inicializar punteros en `DI`, configurar el registro contador `CX` y ejecutar un bucle con `STOSB` o `LOOP` cada vez que el software inicia. Dado que la línea decorativa es fija, invariante y completamente conocida al momento de programar, emitir los bytes directamente en la imagen de `.data` permite que el cargador de DOS los mapee de inmediato en memoria, economizando ciclos de reloj de procesador y simplificando el flujo de ejecución.

---

## 5. Parte 2: Macros con Parámetros y Control de Flujo

### 5.1 Biblioteca Modular: `macros.asm`

```assembly
; ==============================================================================
; macros.asm — Biblioteca modular de macros utilitarias para DOS en NASM
; Estudiante: Julián Ascanio
; ==============================================================================

; Macro: Retorno seguro de control al sistema operativo DOS
%macro fin_dos 0
    mov  ax, 4C00h
    int  21h
%endmacro

; Macro: Emisión de salto de línea canónico (CR + LF)
%macro nueva_linea 0
    push ax
    push dx
    mov  ah, 02h
    mov  dl, 0Dh
    int  21h
    mov  dl, 0Ah
    int  21h
    pop  dx
    pop  ax
%endmacro

; Macro: Imprimir cadena terminada en '$'
; %1 = Puntero o etiqueta de la cadena
%macro print_str 1
    push ax
    push dx
    mov  ah, 09h
    mov  dx, %1
    int  21h
    pop  dx
    pop  ax
%endmacro

; Macro: Imprimir un carácter individual en pantalla
; %1 = Byte o registro con el carácter ASCII
%macro print_char 1
    push ax
    push dx
    mov  ah, 02h
    mov  dl, %1
    int  21h
    pop  dx
    pop  ax
%endmacro

; Macro: Bucle de repetición de cadenas en tiempo de ejecución
; %1 = Etiqueta del mensaje a imprimir
; %2 = Número de iteraciones
%macro repetir_str 2
    push cx
    mov  cx, %2             ; CX actúa como contador decremental
%%ciclo_rep:                ; %% genera una etiqueta local única por expansión
    print_str %1
    loop %%ciclo_rep        ; CX--; si CX != 0 continúa
    pop  cx
%endmacro

; Macro: Conversión e impresión de un entero de 0 a 9 alojado en AL
%macro print_digito 0
    push ax
    push dx
    and  al, 0Fh            ; Aislar nibble bajo
    add  al, 30h            ; Convertir a carácter ASCII ('0'..'9')
    mov  ah, 02h
    mov  dl, al
    int  21h
    pop  dx
    pop  ax
%endmacro

; Macro: Bloque decorativo desenrollado estáticamente mediante el preprocesador
; %1 = Número de copias a emitir en código máquina sin bucle de ejecución
%macro bloque_decorativo 1
    %rep %1
    print_str separador_corto
    %endrep
%endmacro
```

---

### 5.2 Programa Integrador: `programa2.asm`

```assembly
; ==============================================================================
; programa2.asm — Programa Integrador de Macros y Control de Flujo
; Estudiante: Julián Ascanio
; Propósito: Demostrar macros con parámetros, llamadas a procedimientos (CALL/RET),
;            bucle acumulador con LOOP y bifurcaciones condicionales con CMP/Jcc.
; ==============================================================================

%include "macros.asm"       ; Inclusión textual de la biblioteca de macros

section .data
    titulo          db "=== Macros y Control de Flujo ===", 0Dh, 0Ah, 24h
    linea_a         db "[Linea A] Mensaje iterado", 0Dh, 0Ah, 24h
    msg_suma        db "Resultado suma serie (1+2+3): ", 24h
    msg_mayor       db "El valor mayor es: ", 24h
    msg_iguales     db "Los valores son iguales.", 0Dh, 0Ah, 24h
    msg_menor_igual db "AX es menor o igual: ", 24h
    msg_mayor2      db "AX es mayor: ", 24h
    separador_corto db "---", 0Dh, 0Ah, 24h
    msg_fin         db "Fin del programa.", 0Dh, 0Ah, 24h

section .bss
    valor_a         resw 1
    valor_b         resw 1

section .text
    global main

main:
    ; Inicialización de segmento de datos
    mov  ax, @data
    mov  ds, ax

    ; 1. Encabezado principal
    print_str titulo

    ; 2. Demostración de macro con parámetros y bucle en runtime
    repetir_str linea_a, 3

    ; 3. Invocación de subrutina de suma acumulativa (1 + 2 + 3 = 6)
    mov  cx, 3
    call sumar_serie
    print_str msg_suma
    print_digito            ; Imprime el resultado presente en AL ('6')
    nueva_linea

    ; 4. Demostración de comparación 1: 9 vs 4 (Caso AX mayor)
    mov  ax, 9
    mov  bx, 4
    call comparar_e_imprimir

    ; 5. Demostración de comparación 2: 5 vs 5 (Caso igualdad)
    mov  ax, 5
    mov  bx, 5
    call comparar_e_imprimir

    ; 6. Demostración de macro con desenrollado estático (%rep)
    bloque_decorativo 3

    ; 7. Demostración de procedimiento con JLE: 3 vs 8 (Caso AX menor o igual)
    mov  ax, 3
    mov  bx, 8
    call comparar_menor_o_igual

    ; 8. Finalización del programa
    print_str msg_fin
    fin_dos

; ── Procedimiento: Suma Acumulativa de 1 hasta N ──────────────────────────────
; Entrada: CX = Límite superior N
; Salida:  AX = Sumatoria acumulada
sumar_serie:
    push cx
    xor  ax, ax             ; AX = 0 (acumulador)
.paso_suma:
    add  ax, cx             ; AX += CX
    loop .paso_suma         ; Decrementa CX; si CX != 0 salta a .paso_suma
    pop  cx
    ret

; ── Procedimiento: Comparación con JE y JG ───────────────────────────────────
; Entrada: AX, BX
; Evalúa: Si AX == BX o si AX > BX
comparar_e_imprimir:
    push ax
    push bx
    cmp  ax, bx             ; Sustracción interna: actualiza ZF, SF, OF
    je   .son_iguales
    jg   .ax_mayor

    ; Caso BX mayor
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

; ── Procedimiento: Comparación con JLE ─────────────────────────────────────────
; Entrada: AX, BX
; Evalúa: Si AX <= BX mediante salto con signo
comparar_menor_o_igual:
    push ax
    push bx
    cmp  ax, bx
    jle  .menor_o_igual

    ; Caso AX > BX
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
```

---

### 5.3 Compilación, Resolución de DPMI y Ejecución

Al invocar enlazadores de 32 bits bajo DOSBox, ALINK puede emitir la advertencia `rsx_32 loader error: No DPMI-host found!`. Esta limitación se resuelve incorporando el servidor de modo protegido `cwsdpmi.exe` en la carpeta de trabajo, garantizando el enlazado exitoso:

```text
C:\> nasm -f obj programa2.asm -o programa2.obj -l programa2.lst
C:\> cwsdpmi
C:\> alink programa2.obj -oEXE -o programa2.exe -entry main
C:\> programa2.exe
```

**Salida Observada en Pantalla:**
```text
=== Macros y Control de Flujo ===
[Linea A] Mensaje iterado
[Linea A] Mensaje iterado
[Linea A] Mensaje iterado
Resultado suma serie (1+2+3): 6
El valor mayor es: 9
Los valores son iguales.
---
---
---
AX es menor o igual: 3
Fin del programa.
```

**Verificación en el Archivo de Listado (`programa2.lst`):**  
La inspección de `programa2.lst` confirma que cada invocación de `print_str` y `repetir_str` se expande en código máquina con sus respectivas instrucciones de inserción en pila (`push ax`, `push dx`) y llamada al DOS (`int 21h`). La etiqueta local de la macro `repetir_str` se sustituye automáticamente por identificadores secuenciales unívocos (`..@1.ciclo_rep`, `..@2.ciclo_rep`), validando el mecanismo higiénico del preprocesador.

---

### 5.4 Decisiones Técnicas Justificadas de la Parte 2

#### Decisión Técnica 3: %rep frente a LOOP para un Número Fijo de Repeticiones (Paso 9)

> **Dictamen Técnico:** La directiva `%rep` y la instrucción `LOOP` resuelven la repetición de código desde dos paradigmas opuestos: optimización estática en tiempo de preprocesamiento frente a control secuencial dinámico en tiempo de ejecución. Para la macro `bloque_decorativo`, donde la cantidad de impresiones es una constante pequeña y fija (3 copias del separador `"---"`), el desenrollado estático mediante `%rep` es la técnica de mayor eficiencia. Esta directiva replica textualmente las instrucciones `print_str` antes de que comience el ensamblado, generando un flujo lineal de ejecución donde **no existe ninguna instrucción de control de bucle (`MOV CX, n`, `LOOP` o `CMP/Jcc`)**. En consecuencia, el microprocesador procesa las emisiones a la máxima velocidad que permite el bus, con un **costo de cero ciclos adicionales de salto y cero penalizaciones por descarte de cauce (pipeline flushes)**. Por el contrario, si se aplicara `%rep` para 1 000 iteraciones, el tamaño del binario resultante crecería desmedidamente en memoria (`code bloat`). Asimismo, la instrucción `LOOP` (empleada en `repetir_str`) continúa siendo imprescindible en aquellos escenarios donde el número de repeticiones es variable y se determina en tiempo de ejecución (por ejemplo, al capturar un valor numérico ingresado por teclado), condición donde `%rep` resulta inoperante al ser una instrucción exclusiva del preprocesador.

---

#### Decisión Técnica 4: Necesidad de Etiquetas Locales %% en Macros frente a Procedimientos (Paso 10)

> **Dictamen Técnico:** La obligatoriedad del operador de higiene referencial `%%` está supeditada de manera estricta a la presencia de instrucciones de bifurcación dentro de bloques que se expanden múltiples veces en el código fuente. La macro `bloque_decorativo` no requiere etiquetas locales de ningún tipo (`%%` ni tradicionales) porque su cuerpo se compone únicamente de llamadas lineales a `print_str`, careciendo de saltos condicionales o bucles internos. Si se modificara `bloque_decorativo` para incluir una instrucción de salto interno que omitiera la última línea (por ejemplo, mediante `JZ etiqueta`), declarar dicha etiqueta con sintaxis convencional generaría un error fatal de símbolo duplicado durante el ensamblado si la macro se invocara más de una vez en el mismo programa; en ese escenario preciso se torna imperativo anteponer `%%etiqueta`, forzando a NASM a inyectar un contador correlativo único (como `..@1.etiqueta` y `..@2.etiqueta`) en cada punto de expansión. Por el contrario, los procedimientos como `comparar_menor_o_igual` y `comparar_e_imprimir` no se expanden inline sino que se ensamblan una única vez en la sección `.text`; en consecuencia, las etiquetas locales convencionales con prefijo de punto (`.menor_o_igual`, `.fin_cmp2`) resultan plenamente suficientes, dado que el analizador léxico de NASM delimita su visibilidad a la etiqueta global inmediatamente precedente, garantizando que `.fin_comp` en un procedimiento jamás colisione con el `.fin_comp2` del otro.

---

## 6. Registro y Secuencia de Commits

El desarrollo evolutivo del repositorio se encuentra documentado a través de 6 commits estructurados:

```text
commit 1: "Agregar README con descripcion del laboratorio y prerrequisitos"
commit 2: "Implementar programa base con secciones .data, .bss y .text"
commit 3: "Agregar salida de caracteres, recorrido de tabla y linea TIMES CP1-CP4"
commit 4: "Crear biblioteca modular macros.asm con macros utilitarias y parametros"
commit 5: "Implementar programa2.asm con procedimientos sumar_serie y comparar_e_imprimir"
commit 6: "Integrar bloque %rep, comparar_menor_o_igual y decisiones tecnicas finales"
```

---

## 7. Conclusiones

1. **Gestión de Memoria y Segmentación en Modo Real:** En ejecutables DOS de formato MZ (`.exe`), el microprocesador no inicializa de forma automática el registro de segmento de datos `DS`. Es mandatorio que el punto de entrada del programa cargue explícitamente la dirección `@data` en `AX` y la transfiera a `DS`; omitir esta inicialización conduce a que las lecturas y escrituras apunten al Program Segment Prefix (PSP) o a regiones arbitrarias de memoria, provocando fallas silenciosas o congelamientos del sistema.
2. **Eficiencia del Preprocesamiento frente al Runtime:** La utilización estratégica de directivas como `TIMES` y macros con desenrollado mediante `%rep` evidencia que muchas tareas repetitivas pueden transferirse a la fase de compilación. Esto reduce significativamente la carga sobre la ALU al prescindir de registros contadores y bifurcaciones condicionales durante la ejecución del programa.
3. **Acoplamiento entre Aritmética y Bifurcaciones:** Las instrucciones de control condicional (`Jcc`) operan en estricta dependencia con las operaciones aritméticas y de prueba (`CMP`), las cuales actualizan el registro de banderas (`FLAGS`). Comprender la interacción entre las banderas de estado (`ZF`, `SF`, `OF`) permite implementar con total precisión estructuras lógicas equivalentes a `if-else` y bucles controlados directamente a nivel de hardware.