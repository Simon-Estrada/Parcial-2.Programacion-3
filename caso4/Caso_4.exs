Code.require_file("../FolderComun/util2.ex")
Code.require_file("../FolderComun/lector.ex")
Code.require_file("../FolderComun/reporte.ex")
Code.require_file("lector_propuestas.ex")
Code.require_file("validador_parentesis.ex")

defmodule Caso4 do
  @doc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Orquesta la lectura de propuestas, la validación de sus paréntesis
  y la generación del reporte final con los resultados.
  """
  def main(archivo_entrada \\ "propuestas.txt", archivo_salida \\ "verificacion_parentesis.txt") do
    case LectorPropuestas.leer(archivo_entrada) do
      {:error, :no_existe} ->
        Reporte.archivo_faltante(archivo_entrada)

      {:ok, registros} ->
        procesar_propuestas(registros, archivo_salida)
    end
  end

  defp procesar_propuestas(registros, salida) do
    registros
    |> ValidadorParentesis.validar()
    |> ValidadorParentesis.a_lineas()
    |> Reporte.guardar_lineas(salida)

    Util2.mostrar("Verificación terminada. Resultados en #{salida}.", :mensaje)
  end
end
Caso4.main()
