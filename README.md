#  ALU de 8 Bits y Sistema de Memoria Unificada 
### Proyecto Final de vhdl — Universidad del Cauca 

[![FPGA](https://img.shields.io/badge/FPGA-Cyclone%20III%20EP3C16F484C6-blue.svg)](https://www.intel.com)
[![Hardware](https://img.shields.io/badge/Board-Terasic%20DE0-orange.svg)](https://www.terasic.com.tw)
[![Language](https://img.shields.io/badge/Language-VHDL%20IEEE%201076--1993-green.svg)](https://en.wikipedia.org/wiki/VHDL)

---

##  Información del Proyecto

- **Institución:** Universidad del Cauca (Unicauca)
- **Facultad:** Facultad de Ingeniería Electrónica y Telecomunicaciones (FIET)
- **Estudiante:** `Alejandro José Guevara Rada`
- **Docente:** `Fulvio Yesid Vivas Cantero`
- **Herramientas:** Quartus II 13.1 Web Edition, ModelSim 10.1d, Terasic DE0 Board

---

##  ¿De qué se trata este proyecto?

Lo que diseñamos aquí fue el **cerebro y la memoria de una computadora de 8 bits** desde cero, usando hardware digital puro con **VHDL** e implementándolo en una tarjeta FPGA **Terasic DE0 (Altera Cyclone III)**.

Este proyecto nace a partir de la pregunta de cómo hace un procesador por dentro para sumar, restar, tomar decisiones lógicas o guardar información en la RAM, ¡este proyecto es exactamente eso puesto en silicio!

El sistema se compone de dos grandes bloques interconectados:
1. **La ALU (Unidad Aritmético Lógica):** Es la calculadora del sistema. Realiza 8 operaciones distintas (suma, resta, incrementos, decrementos, AND, OR, NOT, etc.) y genera las famosas banderas de estado de un procesador real: **NZVC** (*Negativo*, *Cero*, *Desbordamiento/Overflow* y *Acarreo/Carry*).
2. **El Subsistema de Memoria Unificada:** Un mapa completo de 256 posiciones (de `0x00` a `0xFF`) que incluye:
   - **ROM (128 bytes):** Donde dejamos instrucciones y constantes grabadas de fábrica.
   - **RAM (96 bytes):** Memoria de lectura y escritura para guardar datos en tiempo real.
   - **Puertos de E/S Mapeados en Memoria:** Si escribes en la dirección `0xE0`, ¡se encienden los LEDs verdes de la placa! Y si lees de `0xF0`, lees los switches externos.

Además, todo se visualiza en tiempo real en los **4 displays de 7 segmentos**, con soporte para números con signo (complemento a 2) y sin signo gracias a una implementación hardware del algoritmo **Double Dabble**.

---

##   Imágenes del proyecto montado
<img width="987" height="733" alt="image" src="https://github.com/user-attachments/assets/130c7bb8-08dc-4437-8ef8-f21860091bf3" />
<img width="968" height="683" alt="image" src="https://github.com/user-attachments/assets/f34a1fe6-1140-49e7-80d0-ef46734bcea9" />
<img width="947" height="580" alt="image" src="https://github.com/user-attachments/assets/ab30dfba-5488-46d6-9457-4c52c9596b87" />



##  Simulador Web Interactivo


 **Abrir el archivo [`simulador.html`](simulador.html)**

En el simulador se ve:
- Subir y bajar los switches de la placa DE0 y el dip switch externo.
- Ver los 4 displays de 7 segmentos iluminándose exactamente igual que en la FPGA física.
- Probar sumas, restas, desbordamientos, escritura en RAM y control de LEDs con 1 solo clic mediante presets.

---

##  Arquitectura del Sistema

El proyecto está organizado en módulos limpios y desacoplados:

```
PfinalALU/
├── rtl/
│   ├── alu/
│   │   └── alu.vhd            # Unidad Aritmético Lógica pura (operaciones + banderas NZVC)
│   ├── memory/
│   │   ├── memory.vhd         # Decodificador de direcciones y bus multiplexado
│   │   ├── rom_128x8_sync.vhd # ROM síncrona de 128 bytes (0x00 - 0x7F)
│   │   └── rw_96x8_sync.vhd   # RAM síncrona de 96 bytes (0x80 - 0xDF)
│   └── top/
│       ├── top_fpga.vhd       # Integración total, multiplexor de buses y lógica visual
│       ├── bin8_to_bcd.vhd    # Convertidor binario a BCD (Double Dabble con signo/sin signo)
│       ├── hex7seg.vhd        # Decodificador activo en bajo para displays (soporta signo menos)
│       └── debouncer.vhd      # Filtro antirrebote a 50 MHz para los pulsadores mecánicos
├── constraints/
│   └── de0_pins.qsf           # Asignación física exacta de pines para la Terasic DE0
├── simulador.html             # Simulador web interactivo del proyecto
└── README.md                  # Este archivo que estás leyendo
```

###  Mapa de Memoria (256 Bytes)

| Rango de Direcciones | Tipo de Memoria | Descripción / Función |
| :---: | :---: | :--- |
| `0x00` – `0x7F` (0 a 127) | **ROM** | Memoria de solo lectura. Contiene datos fijos y constantes precargadas. |
| `0x80` – `0xDF` (128 a 223) | **RAM** | Memoria de lectura/escritura (96 bytes). Guarda datos que cambian en caliente. |
| `0xE0` – `0xEF` (224 a 239) | **Salida (E/S)** | Puertos de salida. En `0xE0` los bits `[3:0]` van conectados directo a los LEDs `LEDG[9:6]`. |
| `0xF0` – `0xFF` (240 a 255) | **Entrada (E/S)**| Puertos de entrada. En `0xF0` se leen los datos externos. |

---

## Controles en la FPGA

Para controlar el sistema usamos los **10 switches de la tarjeta DE0**, **2 botones pulsadores** y un **DIP switch externo de 12 posiciones** conectado a los puertos GPIO.

### 1. Switches en la Placa (`SW[9:0]`)
- **`SW[9]` — Selector de Modo General:**
  - `0`: **Modo ALU Directo**. Muestra en los displays el resultado de la operación seleccionada.
  - `1`: **Modo Memoria**. Muestra en los displays el dato leído de la dirección actual del bus.
- **`SW[8:6]` — Selector de Operación de la ALU (`ALU_Sel`):**
  - `000`: Suma ($A + B$)
  - `001`: Resta ($A - B$)
  - `010`: Operación AND bit a bit ($A \text{ and } B$)
  - `011`: Operación OR bit a bit ($A \text{ or } B$)
  - `100`: Incremento ($A + 1$)
  - `101`: Decremento ($A - 1$)
  - `110`: Operación NOT ($\text{not } A$)
  - `111`: Passthrough / Buffer (pasa el dato de $A$)
- **`SW[5]` — Habilitador de Escritura en Memoria (`writen`):**
  - `1`: Permite escribir el dato en la RAM o en los puertos de salida al pulsar el reloj manual.
- **`SW[3:0]` — Nibble Alto del Operando B (`B[7:4]`):**
  - Permite configurar los 4 bits más significativos del operando B desde la misma placa.

### 2. DIP Switch Externo (12 posiciones en Protoboard)
- **`DIP 1..4`:** Operando **A** (bits `A[3:0]`). Los bits altos `A[7:4]` están a 0 para pruebas rápidas.
- **`DIP 5..8`:** Nibble bajo del Operando **B** (bits `B[3:0]`).
- **`DIP 9`:** Selector de formato de visualización (`HEX` = 1 / `Decimal` = 0).
- **`DIP 10`:** Selector de fuente para el bus de direcciones de memoria.
- **`DIP 11`:** **Modo Signo:** `0` = Sin signo (rango 0 a 255/510), `1` = Con signo (Complemento a 2, rango -128 a +127).
- **`DIP 12`:** Bit más significativo de la dirección de memoria (`address[7]`), ideal para saltar rápido entre ROM (`0x00`) y RAM (`0x80`).

### 3. Botones Pulsadores (`KEY[1:0]`)
- **`KEY[0]`:** Reset maestro del sistema (activo en bajo).
- **`KEY[1]`:** Reloj manual con filtro antirrebote de 20 ms. Cada pulsación escribe en memoria cuando `SW5 = 1`.

### 4. Luces LED (`LEDG[9:0]`)
- **`LEDG[9:6]`:** Muestran el dato guardado en el puerto de salida `0xE0` (bits `port_out_00[3:0]`).
- **`LEDG[5]`:** Indica si la escritura en memoria está habilitada (`SW5 = 1`).
- **`LEDG[4]`:** Indica el modo actual (`0` = ALU, `1` = Memoria).
- **`LEDG[3]`:** Bandera **N** (Negativo: bit 7 activo en resultado).
- **`LEDG[2]`:** Bandera **Z** (Cero: resultado igual a cero).
- **`LEDG[1]`:** Bandera **V** (Desbordamiento / Overflow en complemento a 2).
- **`LEDG[0]`:** Bandera **C** (Acarreo / Carry generado).

---

