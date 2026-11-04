defmodule Validador do

  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3

  Validación de tareas leídas desde un archivo csv en este caso
  un archivo 'tareas.csv'
  No se usa Enum ni stream con el fin de aplicar la recursividad
  en todo momento.

  """

  @doc """
    Realiza la validacion de los registros que entrega
    LectorTareas.leer/1
    retornando {:ok, tareas} si no hay errores o {:error, lista_errores} si los hay
  """
  def validar(registros) do
    {errores_formato, entradas, tareas} = separar(registros)

    errores =
      errores_formato ++
        ids_duplicados(entradas, []) ++
        ids_con_caracteres_prohibidos(entradas) ++
        valores_invalidos(entradas) ++
        autodependencias(entradas) ++
        dependencias_repetidas(entradas) ++
        dependencias_desconocidas(entradas, tareas) ++
        ciclos(tareas)

    case errores do
      [] -> {:ok, tareas}
      _ -> {:error, errores}
    end
  end

  # Estas funciones permiten separar los registros en categorias como
  # errores de formato, entradas correctas.
  # Caso base
  defp separar([]), do: {[], [], []}
  # Caso recursivo correcto
  defp separar([{:ok, linea, tarea} | resto]) do
    {errores, entradas, tareas} = separar(resto)
    {errores, [{linea, tarea} | entradas], [tarea | tareas]}
  end
  # Caso recursivo incorrecto
  defp separar([{:error, linea, motivo} | resto]) do
    {errores, entradas, tareas} = separar(resto)
    {["[Línea #{linea}] Formato incorrecto: #{motivo}" | errores], entradas, tareas}
  end

  # Aqui se verifica si se encuentran ids duplicados
  # Es decir, si hay dos tareas con el mismo id notifica que hay tareas con dicho inconveniente
  # Caso base
  defp ids_duplicados([], _vistos), do: []
  # Caso recursivo
  defp ids_duplicados([{linea, t} | resto], vistos) do
    if contiene?(vistos, t.id) do
      ["[Línea #{linea}, tarea #{t.id}] ID duplicado" | ids_duplicados(resto, vistos)]
    else
      ids_duplicados(resto, [t.id | vistos])
    end
  end

  # Se solicita en el parcial que los ids no contengan los caracteres ';' ni '|',
  # y tampoco encontrarsen vacios. Esta funcion recorre la lista y revisa aquellas que lo incumplen.
  # Caso base
  defp ids_con_caracteres_prohibidos([]), do: []

  # Caso recursivo
  defp ids_con_caracteres_prohibidos([{linea, t} | resto]) do
    error =
      cond do
        t.id == "" ->
          ["[Línea #{linea}] El ID está vacío"]

        tiene_caracter_prohibido?(String.graphemes(t.id)) ->
          ["[Línea #{linea}, tarea #{t.id}] El ID contiene un carácter no permitido (; o |)"]

        true ->
          []
      end

    error ++ ids_con_caracteres_prohibidos(resto)
  end

  # Funciones privadas auxiliares que validan los caracteres
  # Tienen Recursion
  # Casos bases
  defp tiene_caracter_prohibido?([]), do: false
  defp tiene_caracter_prohibido?([";" | _resto]), do: true
  defp tiene_caracter_prohibido?(["|" | _resto]), do: true
  # Caso recursivo
  defp tiene_caracter_prohibido?([_otro | resto]), do: tiene_caracter_prohibido?(resto)

  # Estas funciones permiten validar los valores numericos de la duracion y plazo.
  # Caso base
  defp valores_invalidos([]), do: []
  # Caso recursivo
  defp valores_invalidos([{linea, t} | resto]) do
    error_duracion =
      if duracion_valida?(t.duracion),
        do: [],
        else: ["[Línea #{linea}, tarea #{t.id}] Duración inválida (debe ser entero positivo)"]

    error_plazo =
      if plazo_valido?(t.plazo),
        do: [],
        else: ["[Línea #{linea}, tarea #{t.id}] Plazo inválido (debe ser entero no negativo)"]

    error_duracion ++ error_plazo ++ valores_invalidos(resto)
  end
  # Funciones privadas auxiliares que validan los valores numericos de duracion y plazo
  # Tienen Recursion
  defp duracion_valida?(d) when is_integer(d) and d > 0, do: true
  defp duracion_valida?(_), do: false

  defp plazo_valido?(p) when is_integer(p) and p >= 0, do: true
  defp plazo_valido?(_), do: false

  # verifica si una tarea depende de sí misma, si tiene dependencias repetidas, si depende de tareas que no existen y si hay ciclos de dependencias.
  defp autodependencias([]), do: []
  # Caso recursivo
  defp autodependencias([{linea, t} | resto]) do
    if contiene?(t.dependencias, t.id) do
      ["[Línea #{linea}, tarea #{t.id}] La tarea depende de sí misma" | autodependencias(resto)]
    else
      autodependencias(resto)
    end
  end

  # Verifican si una tarea tiene deoendencias repetidas.
  # Caso base
  defp dependencias_repetidas([]), do: []
  # Caso recursivo
  defp dependencias_repetidas([{linea, t} | resto]) do
    if tiene_repetidos?(t.dependencias) do
      ["[Línea #{linea}, tarea #{t.id}] Tiene dependencias repetidas" | dependencias_repetidas(resto)]
    else
      dependencias_repetidas(resto)
    end
  end
  # Verifica si una tarea depende de tareas que no existen.
  # Caso base
  defp dependencias_desconocidas([], _tareas), do: []
  # Caso recursivo
  defp dependencias_desconocidas([{linea, t} | resto], tareas) do
    desconocidas_de(t.dependencias, t.id, linea, tareas) ++
      dependencias_desconocidas(resto, tareas)
  end
  # Funciones privadas auxiliares que validan las dependencias desconocidas
  # Tienen Recursion
  # Caso base
  defp desconocidas_de([], _id, _linea, _tareas), do: []
  # Caso recursivo
  defp desconocidas_de([dep | resto], id, linea, tareas) do
    if buscar_tarea(tareas, dep) == nil and not contiene?(resto, dep) do
      ["[Línea #{linea}, tarea #{id}] Depende de '#{dep}', que no existe"
       | desconocidas_de(resto, id, linea, tareas)]
    else
      desconocidas_de(resto, id, linea, tareas)
    end
  end
  # Para esta parte se requiere que se verifique si hay ciclos de dependencias, es decir, si una tarea depende de otra que a su vez depende de la primera.
  # resulta que se debe solo se acepta un ciclo cuando se encuentra desde su id menor
  # si tenemos X > Y > X, se reporta una vez desde X
  defp ciclos(tareas), do: ciclos_desde_cada(tareas, tareas)
  # caso base
  defp ciclos_desde_cada([], _todas), do: []
  # caso recursivo
  defp ciclos_desde_cada([t | resto], todas) do
    buscar_ciclos(t.id, t.id, [t.id], todas) ++ ciclos_desde_cada(resto, todas)
  end
  # Funciones privadas auxiliares que buscan ciclos de dependencias
  defp buscar_ciclos(inicio, actual, camino, todas) do
    case buscar_tarea(todas, actual) do
      nil -> []
      tarea -> explorar(tarea.dependencias, inicio, camino, todas)
    end
  end

  defp explorar([], _inicio, _camino, _todas), do: []

  defp explorar([dep | resto], inicio, camino, todas) do
    cond do
      contiene?(resto, dep) ->
        explorar(resto, inicio, camino, todas)

      dep == inicio and camino != [inicio] ->
        ["Ciclo de dependencias: " <> unir(camino ++ [inicio], " -> ")
         | explorar(resto, inicio, camino, todas)]

      dep == inicio ->
        explorar(resto, inicio, camino, todas)

      dep < inicio ->
        explorar(resto, inicio, camino, todas)

      contiene?(camino, dep) ->
        explorar(resto, inicio, camino, todas)

      true ->
        buscar_ciclos(inicio, dep, camino ++ [dep], todas) ++
          explorar(resto, inicio, camino, todas)
    end
  end


  defp contiene?([], _elemento), do: false
  defp contiene?([elemento | _resto], elemento), do: true
  defp contiene?([_otro | resto], elemento), do: contiene?(resto, elemento)

  defp tiene_repetidos?([]), do: false

  defp tiene_repetidos?([primero | resto]) do
    contiene?(resto, primero) or tiene_repetidos?(resto)
  end

  defp buscar_tarea([], _id), do: nil
  defp buscar_tarea([%Tarea{id: id} = tarea | _resto], id), do: tarea
  defp buscar_tarea([_otra | resto], id), do: buscar_tarea(resto, id)

  defp unir([], _separador), do: ""
  defp unir([ultimo], _separador), do: ultimo
  defp unir([primero | resto], separador), do: primero <> separador <> unir(resto, separador)
end
