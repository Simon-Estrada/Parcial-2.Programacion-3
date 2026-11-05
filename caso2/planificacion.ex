defmodule Planificador do
  @moduledoc """
  Módulo encargado de la búsqueda recursiva, evaluación y escritura en flujo
  de todos los órdenes de ejecución válidos para una red de tareas con dependencias.

  Implementa las reglas del Problema 2:
  - Búsqueda determinista probando tareas habilitadas alfabéticamente por ID.
  - Cálculo de penalizaciones por incumplimiento de plazos.
  - Escritura progresiva en `planes.csv` para evitar cargar todos los planes en memoria.
  - Generación del archivo `resumen_tareas.txt` y reporte por pantalla.
  """

  @doc """
  Genera todos los planes válidos a partir de una lista de structs `%Tarea{}`.

  ## Parámetros
    - `tareas`: Lista de estructuras `%Tarea{}` validadas.
    - `ruta_csv`: Ruta del archivo CSV donde se escribirán los planes (por defecto `"planes.csv"`).
    - `ruta_resumen`: Ruta del archivo de texto para el resumen (por defecto `"resumen_tareas.txt"`).

  ## Retorno
    - `{:ok, %{contador: integer(), min_penalizacion: integer(), mejores_planes: [%Plan{}]}}`
    - `{:ok, :proyecto_vacio}` si la lista de tareas está vacía.

  ## Ejemplo
      iex> tareas = [
      ...>   %Tarea{id: "A", duracion: 3, plazo: 4, dependencias: []},
      ...>   %Tarea{id: "B", duracion: 2, plazo: 5, dependencias: ["A"]}
      ...> ]
      iex> Planificador.generar_planes(tareas, "planes.csv", "resumen_tareas.txt")
      {:ok, %{contador: 1, min_penalizacion: 0, mejores_planes: [%Plan{...}]}}
  """
  @spec generar_planes(list(%Tarea{}), String.t(), String.t()) :: {:ok, map() | :proyecto_vacio}
  def generar_planes(tareas, ruta_csv \\ "planes.csv", ruta_resumen \\ "resumen_tareas.txt")

  # Caso cuando no hay tareas en el proyecto (especificado en los requisitos)
  def generar_planes([], _ruta_csv, ruta_resumen) do
    contenido = "Proyecto vacío: no existen tareas para planificar.\n"
    File.write!(ruta_resumen, contenido)
    IO.puts(contenido)
    {:ok, :proyecto_vacio}
  end

  def generar_planes(tareas, ruta_csv, ruta_resumen) do
    # Apertura de archivo en modo de escritura progresiva en flujo UTF-8
    archivo_csv = File.open!(ruta_csv, [:write, :utf8])
    IO.write(archivo_csv, "id_orden; duracion_total; penalizacion\n")

    # Creación del mapa indexado por ID para acceso rápido: %{"A" => %Tarea{...}}
    mapa_tareas = Map.new(tareas, fn t -> {t.id, t} end)

    # Estado inicial de acumulación (conteo global y registro de óptimos)
    estado_inicial = %{
      contador: 0,
      min_penalizacion: nil,
      mejores_planes: []
    }

    # Inicio de la exploración recursiva por fuerza bruta con poda implícita de dependencias
    estado_final =
      buscar_planes(
        mapa_tareas,
        _pendientes = Map.keys(mapa_tareas),
        _completadas = %{},
        _tiempo_actual = 0,
        _penalizacion_acumulada = 0,
        _orden_actual = [],
        archivo_csv,
        estado_inicial
      )

    File.close(archivo_csv)

    # Generación y despliegue del resumen
    escribir_y_mostrar_resumen(estado_final, ruta_resumen)

    {:ok, estado_final}
  end

  # ============================================================================
  # Algoritmo de Búsqueda Recursiva / Backtracking
  # ============================================================================

  # Caso base: No quedan tareas pendientes, se completó un plan válido
  defp buscar_planes(
         _mapa_tareas,
         [] = _pendientes,
         completadas,
         tiempo_actual,
         penalizacion_acumulada,
         orden_actual,
         archivo_csv,
         estado
       ) do
    orden_final = Enum.reverse(orden_actual)
    nuevo_contador = estado.contador + 1

    # Construcción de la estructura %Plan{} resultante
    plan = %Plan{
      orden: orden_final,
      finalizaciones: completadas,
      penalizacion: penalizacion_acumulada
    }

    # Formateo de los IDs separados por espacio
    string_orden = Enum.join(orden_final, " ")

    # Escritura progresiva inmediata en disco sin acumular strings gigantes en RAM
    IO.write(
      archivo_csv,
      "#{nuevo_contador}; #{string_orden}; #{tiempo_actual}; #{penalizacion_acumulada}\n"
    )

    # Actualización en caliente del estado del resumen
    actualizar_estado_resumen(estado, nuevo_contador, plan, penalizacion_acumulada)
  end

  # Caso recursivo: Selecciona e itera sobre las tareas cuyas dependencias están satisfechas
  defp buscar_planes(
         mapa_tareas,
         pendientes,
         completadas,
         tiempo_actual,
         penalizacion_acumulada,
         orden_actual,
         archivo_csv,
         estado
       ) do
    # Identificar tareas habilitadas (aquellas cuyas dependencias están completadas)
    habilitadas =
      pendientes
      |> Enum.filter(fn id ->
        tarea = Map.fetch!(mapa_tareas, id)
        dependencias_satisfechas?(tarea.dependencias, completadas)
      end)
      |> Enum.sort() # Garantiza orden alfabético estricto por ID

    # Recorrer cada rama habilitada pasando el acumulador de estado
    Enum.reduce(habilitadas, estado, fn id_tarea, estado_acc ->
      tarea = Map.fetch!(mapa_tareas, id_tarea)

      # Tiempos de finalización y cálculo de penalización
      fin_tarea = tiempo_actual + tarea.duracion
      penalizacion_tarea = max(0, fin_tarea - tarea.plazo)

      nuevas_pendientes = List.delete(pendientes, id_tarea)
      nuevas_completadas = Map.put(completadas, id_tarea, fin_tarea)

      # Llamada recursiva profundizando en el árbol de decisión
      buscar_planes(
        mapa_tareas,
        nuevas_pendientes,
        nuevas_completadas,
        fin_tarea,
        penalizacion_acumulada + penalizacion_tarea,
        [id_tarea | orden_actual],
        archivo_csv,
        estado_acc
      )
    end)
  end

  # Verificación recursiva de dependencias frente al mapa de tareas completadas
  defp dependencias_satisfechas?([], _completadas), do: true

  defp dependencias_satisfechas?([dep | resto], completadas) do
    if Map.has_key?(completadas, dep) do
      dependencias_satisfechas?(resto, completadas)
    else
      false
    end
  end

  # Actualiza la penalización mínima y conserva los planes empatados en el óptimo
  defp actualizar_estado_resumen(estado, contador, plan, penalizacion) do
    case estado.min_penalizacion do
      nil ->
        %{estado | contador: contador, min_penalizacion: penalizacion, mejores_planes: [plan]}

      min_actual when penalizacion < min_actual ->
        %{estado | contador: contador, min_penalizacion: penalizacion, mejores_planes: [plan]}

      min_actual when penalizacion == min_actual ->
        %{estado | contador: contador, mejores_planes: estado.mejores_planes ++ [plan]}

      _ ->
        %{estado | contador: contador}
    end
  end

  # Escribe `resumen_tareas.txt` e imprime la salida estándar por consola
  defp escribir_y_mostrar_resumen(%{contador: 0}, ruta_resumen) do
    texto = "No existe ningún plan válido para la red de tareas proporcionada.\n"
    File.write!(ruta_resumen, texto)
    IO.puts(texto)
  end

  defp escribir_y_mostrar_resumen(estado, ruta_resumen) do
    lineas_mejores =
      estado.mejores_planes
      |> Enum.map(fn plan ->
        "  - Orden: #{Enum.join(plan.orden, " ")} | Penalización: #{plan.penalizacion}"
      end)
      |> Enum.join("\n")

    resumen = """
    ==================================================
    RESUMEN DE PLANIFICACIÓN DE TAREAS
    ==================================================
    Total de planes válidos encontrados : #{estado.contador}
    Penalización mínima obtenida       : #{estado.min_penalizacion}
    Planes óptimos:
    #{lineas_mejores}
    ==================================================
    """

    File.write!(ruta_resumen, resumen)
    IO.puts(resumen)
  end
end
