Code.require_file("../FolderComun/Util2.ex")
Code.require_file("../FolderComun/lector.ex")
Code.require_file("../FolderComun/reporte.ex")
Code.require_file("tarea.ex")
Code.require_file("lector_tareas.ex")
Code.require_file("validador.ex")
Code.require_file("planificacion.ex")
Code.require_file("svg_gantt.ex")

defmodule Caso2 do

  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Módulo principal del caso de estudio 2.
  Contiene la función `main/2` que orquesta la lectura, validación y reporte de la red de tareas.
  """
  @doc """
  Orquesta la lectura, validación y reporte de la red de tareas.
  Recibe los nombres de los archivos para permitir flexibilidad y pruebas.
  """
  def main(archivo_entrada \\ "tareas.csv", archivo_salida \\ "validacion_tareas.txt") do
    case LectorTareas.leer(archivo_entrada) do
      {:error, :no_existe} ->
        Reporte.archivo_faltante(archivo_entrada)

      {:ok, registros} ->
        procesar_registros(registros, archivo_salida)
    end
  end

  defp procesar_registros(registros, salida) do
    case Validador.validar(registros) do
      {:ok, []} ->
        Reporte.guardar_lineas(["Sin errores de validación (proyecto vacío)."], salida)
        Util2.mostrar("Proyecto vacío: no hay planes que enumerar.", :mensaje)

        {:ok, resultado} = Planificador.generar_planes([], "planes.csv", "resumen_tareas.txt")
          SvgGantt.generar_svg(resultado, [], "mejor_plan.svg")

      {:ok, tareas} ->
        Reporte.guardar_lineas(["Sin errores de validación."], salida)
        Util2.mostrar("Red de tareas válida (#{length(tareas)} tareas).", :mensaje)

        {:ok, resultado} = Planificador.generar_planes(tareas, "planes.csv", "resumen_tareas.txt")
          SvgGantt.generar_svg(resultado, tareas, "mejor_plan.svg")

      {:error, errores} ->
        Reporte.guardar_lineas(errores, salida)
        Util2.mostrar("La red de tareas tiene errores. Revise #{salida}.", :mensaje)
    end
  end
end


# Correcion final
case System.argv() do
  [entrada] -> Caso2.main(entrada)
  _ -> Caso2.main()
end
