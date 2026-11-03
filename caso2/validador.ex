defmodule Validador do

  def validar_y_reportar(registros, ruta_salida \\ "validacion_tareas.txt") do
    {errores_parseo, tareas} = separar_parseo(registros, [], [])

    errores_duplicados = validar_ids_duplicados(tareas, [])
    errores_valores = validar_valores_numericos(tareas, [])
    errores_autodep = validar_autodependencias(tareas, [])
    errores_desconocidas = validar_dependencias_desconocidas(tareas, tareas, [])
    errores_repetidas = validar_dependencias_repetidas(tareas, [])
    errores_ciclos = detectar_ciclos(tareas)

    todos_los_errores =
      errores_parseo ++
        errores_duplicados ++
        errores_valores ++
        errores_autodep ++
        errores_desconocidas ++
        errores_repetidas ++
        errores_ciclos

    contenido_reporte = generar_contenido_reporte(todos_los_errores)
    File.write(ruta_salida, contenido_reporte)

    if todos_los_errores == [] do
      {:ok, tareas}
    else
      {:error, "La red de tareas contiene errores. Consulta '#{ruta_salida}'."}
    end
  end


  defp separar_parseo([], errores, tareas), do: {inverso(errores, []), inverso(tareas, [])}

  defp separar_parseo([head | tail], errores, tareas) do
    case head do
      {:ok, linea, tarea} ->
        separar_parseo(tail, errores, [tarea | tareas])

      {:error, linea, mensaje} ->
        separar_parseo(tail, [{linea, "Error de sintaxis: #{mensaje}"} | errores], tareas)
    end
  end

  defp validar_ids_duplicados([], _revisados), do: []

  defp validar_ids_duplicados([t | resto], revisados) do
    if contiene?(revisados, t.id) do
      [{"General", "ID duplicado detectado: #{t.id}"} | validar_ids_duplicados(resto, revisados)]
    else
      validar_ids_duplicados(resto, [t.id | revisados])
    end
  end


  defp validar_valores_numericos([], _acc), do: []

  defp validar_valores_numericos([t | resto], acc) do
    errores = []

    errores =
      if t.duracion == :invalido or t.duracion <= 0,
        do: [{"Tarea #{t.id}", "Duración inválida (debe ser entera positiva)"} | errores],
        else: errores

    errores =
      if t.plazo == :invalido or t.plazo < 0,
        do: [{"Tarea #{t.id}", "Plazo inválido (debe ser entero no negativo)"} | errores],
        else: errores

    errores ++ validar_valores_numericos(resto, acc)
  end


  defp validar_autodependencias([], _acc), do: []

  defp validar_autodependencias([t | resto], acc) do
    if contiene?(t.dependencias, t.id) do
      [{"Tarea #{t.id}", "La tarea depende de sí misma"} | validar_autodependencias(resto, acc)]
    else
      validar_autodependencias(resto, acc)
    end
  end

  defp validar_dependencias_desconocidas([], _todas, _acc), do: []

  defp validar_dependencias_desconocidas([t | resto], todas_tareas, acc) do
    errores_depend = verificar_deps_en_lista(t.dependencias, todas_tareas, t.id)
    errores_depend ++ validar_dependencias_desconocidas(resto, todas_tareas, acc)
  end

  defp verificar_deps_en_lista([], _todas, _id_tarea), do: []

  defp verificar_deps_en_lista([depend | resto_deps], todas_tareas, id_tarea) do
    if existe_tarea_id?(todas_tareas, depend) do
      verificar_deps_en_lista(resto_deps, todas_tareas, id_tarea)
    else
      [
        {"Tarea #{id_tarea}", "Dependencia desconocida: '#{depend}' no existe"}
        | verificar_deps_en_lista(resto_deps, todas_tareas, id_tarea)
      ]
    end
  end

  defp validar_dependencias_repetidas([], _acc), do: []

  defp validar_dependencias_repetidas([t | resto], acc) do
    if tiene_duplicados?(t.dependencias) do
      [
        {"Tarea #{t.id}", "Tiene dependencias repetidas"}
        | validar_dependencias_repetidas(resto, acc)
      ]
    else
      validar_dependencias_repetidas(resto, acc)
    end
  end


  defp detectar_ciclos(tareas) do
    verificar_ciclos_en_nodos(tareas, tareas, [])
  end

  defp verificar_ciclos_en_nodos([], _todas, errores), do: inverso(errores, [])

  defp verificar_ciclos_en_nodos([t | resto], todas, errores) do
    if hay_ciclo_desde?(t.id, [t.id], todas) do
      verificar_ciclos_en_nodos(resto, todas, [
        {"Tarea #{t.id}", "Se detectó un ciclo en las dependencias"} | errores
      ])
    else
      verificar_ciclos_en_nodos(resto, todas, errores)
    end
  end

  defp hay_ciclo_desde?(id_actual, visitados, tareas) do
    tarea = buscar_tarea(tareas, id_actual)

    if tarea == nil or tarea.dependencias == [] do
      false
    else
      recorrer_vecinos(tarea.dependencias, visitados, tareas)
    end
  end

  defp recorrer_vecinos([], _visitados, _tareas), do: false

  defp recorrer_vecinos([vecino | resto], visitados, tareas) do
    cond do
      contiene?(visitados, vecino) -> true
      hay_ciclo_desde?(vecino, [vecino | visitados], tareas) -> true
      true -> recorrer_vecinos(resto, visitados, tareas)
    end
  end
  
  defp inverso([], acc), do: acc
  defp inverso([h | t], acc), do: inverso(t, [h | acc])

  defp contiene?([], _elem), do: false

  defp contiene?([h | t], elem) do
    if h == elem, do: true, else: contiene?(t, elem)
  end

  defp existe_tarea_id?([], _id), do: false

  defp existe_tarea_id?([t | resto], id) do
    if t.id == id, do: true, else: existe_tarea_id?(resto, id)
  end

  defp buscar_tarea([], _id), do: nil

  defp buscar_tarea([t | resto], id) do
    if t.id == id, do: t, else: buscar_tarea(resto, id)
  end

  defp tiene_duplicados?([]), do: false

  defp tiene_duplicados?([h | t]) do
    if contiene?(t, h), do: true, else: tiene_duplicados?(t)
  end

  defp generar_contenido_reporte([]) do
    "# Reporte de validación de tareas: Sin errores detectados.\n"
  end

  defp generar_contenido_reporte(errores) do
    errores
    |> Enum.map(fn {ubicacion, mensaje} -> "[#{ubicacion}] #{mensaje}\n" end)
    |> Enum.join("")
  end
end
