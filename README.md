# Parcial 2 - Recursividad y Structs
## Informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
Para este parcial se dieron una serie de casos, de los cuales escogimos realizar la pareja compuesta por el caso 2 y caso 4. 
> No se utilizo mix para este parcial.
```
Parcial 2/
├── FolderComun/   util2.ex, lector.ex, reporte.ex
├── caso2/         tarea.ex, lector_tareas.ex, validador.ex, Caso_2.exs, tareas.csv
└── caso4/         lector_propuestas.ex, validador_parentesis.ex, Caso_4.exs, propuestas.txt
```
Para ejecutar el codigo debe hacerse desde la carpeta de cada caso, de esta manera:
```
cd caso2
elixir Caso_2.exs

cd ../caso4
elixir Caso_4.exs
```
Archivos de salida: `caso2/validacion_tareas.txt y caso4/verificacion_parentesis.txt.`
# Nota:
Como las validaciones se necesitan probar vamos a usar los siguientes comandos al compilar el caso 2, con el fin de probar diferentes situaciones donde el archivo csv este involucrado.
```
elixir Caso_2.exs                          
elixir Caso_2.exs Pruebas/invalido.csv     
elixir Caso_2.exs Pruebas/ciclos.csv      
elixir Caso_2.exs Pruebas/vacio.csv        
elixir Caso_2.exs Pruebas/noexiste.csv    

## Caso 4: parentesis balanceados con profundidad maxima
`elixir Caso_4.exs` (desde `caso4/`) valida las propuestas, genera las cadenas de cada par `n;profundidad_max` de `parametros.csv` con un Stream recursivo y perezoso, escribe la primera solucion de `n=18, p=18` y consume el Stream infinito `n=1,2,3...` (con `p=n`) hasta el primer total >= 1000 (`n=8`, 1430).

Archivos nuevos: `lector_parametros.ex`, `generador_parentesis.ex`, `escritor_parentesis.ex` y `parametros.csv`.

Salidas en `caso4/`: `parentesis_n<N>_p<P>.txt`, `primera_n18_p18.txt` y `secuencia_parentesis.csv`.

Argumentos opcionales: `elixir Caso_4.exs <propuestas> <salida_verificacion> <parametros>`

Pruebas:
```
elixir Caso_4.exs propuestas.txt verificacion_parentesis.txt Pruebas/parametros_mixtos.csv
elixir Caso_4.exs propuestas.txt verificacion_parentesis.txt Pruebas/parametros_limite.csv
elixir Caso_4.exs propuestas.txt verificacion_parentesis.txt Pruebas/noexiste.csv
```
> No poner `18;18` en `parametros.csv`: generaria cientos de millones de lineas.