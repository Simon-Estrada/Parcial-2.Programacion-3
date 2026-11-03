defmodule Validador do

  def validar_todo(registros) do
    {errores_parser, tareas} = separar_parser(registros, [], [])

    if errores_parser != [] do
      {:error, errores_parser}
    else
      errores_duplicados = validar_ids_duplicados(tareas, [])
      errores_valores = validar_valores_numericos(tareas, [])
      errores_autodep = validar_autodependencias(tareas, [])
      errores_desconocidas = validar_dependencias_desconocidas(tareas, tareas, [])
      errores_repetidas = validar_dependencias_repetidas(tareas, [])
      errores_ciclos = detectar_ciclos(tareas, [])

      resumen_errores =
        errores_duplicados ++
        errores_valores ++
        errores_autodep ++
        errores_desconocidas ++
        errores_repetidas ++
        errores_ciclos

      if resumen_errores == [] do
        {:ok, tareas}

      else
        {:error, resumen_errores}
      end
    end
  end

  defp separar_parser([], errores, tareas), do: {inverso(errores, []), inverso(tareas, [])}
  defp separar_parser([head | tail], errores, tareas) do
    case head do
      {:ok, linea, tarea} ->
        separar_parser(tail, errores, [tarea | tareas])
        {:error, linea, mensaje} ->
          separar_parser(tail, [{linea, mensaje} | errores], tareas)
    end
  end

  defp validar_ids_duplicados([], _revisados), do: []
  defp validar_ids_duplicados([tarea | resto], revisados) do
    if tiene_id?(revisados, tarea.id) do
      [{"General", "El ID esta duplicado #{tarea.id}"} | validar_ids_duplicados(resto, revisados)]
    else
      validar_ids_duplicados(resto, [tarea.id | revisados])
    end
  end

  defp tiene_id?([], _id), do: false
  defp tiene_id?([head | tail], id) do
    if head == id, do: true, else: tiene_id?(tail, id)
  end

  defp validar_valores_numericos([], _acc), do: []
  defp validar_valores_numericos([tarea | resto], acc) do
    errores = []

    errores = if tarea.duracion == :invalido or tarea.duracion <= 0 do
      [{"Tarea: #{tarea.id}", "Duracion invalida: debe tener un numero entero positivo."} | errores]
    else
      errores
    end

    errores = if tarea.plazo == :invalido or tarea.plazo < 0 do
      [["Tarea #{tarea.id}", "Plazo invalido: debe ser un numero entero no negativo"] | errores]
    else
      errores
    end

    errores ++ validar_valores_numericos(resto, acc)
  end

  defp validar_autodependencias([], _acc), do: []
  defp validar_autodependencias([tarea | resto], acc) do
    if tiene_elemento?(tarea.dependencias, tarea.id) do
      [{"Tarea #{tarea.id}", "La tarea depende de si misma :("} | validar_autodependencias(resto, acc)]
    else
      validar_autodependencias(resto, acc)
    end
  end

  defp inverso([], acumulador), do: acumulador
  defp inverso([head | tail], acumulador), do: inverso(tail, [head | acumulador])

  defp tiene_elemento?([], _elemento), do: false
  defp tiene_elemento?([head | tail], elemento) do
    if head == elemento, do: true, else: tiene_elemento?(tail, elemento)
  end

  defp validar_dependencias_desconocidas(_t, _todas, _acc), do: []
  defp validar_dependencias_repetidas(_t, _acc), do: []
  defp detectar_ciclos(_t, _acc), do: []


end
