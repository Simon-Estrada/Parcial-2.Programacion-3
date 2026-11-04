defmodule Reporte do
  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3

  Módulo encargado de gestionar los reportes del sistema, como avisar cuando
  falta un archivo de entrada o guardar listas de líneas en archivos de salida
  utilizando recursión para la escritura progresiva.
  """
  @doc """
    Muestra un mensaje de aviso en la salida de errores estándar
    cuando no se encuentra un archivo requerido.
  """
   def archivo_faltante(ruta) do
    Util2.mostrar("Aviso: no se encontró el archivo #{ruta}", :error)
  end


  def guardar_lineas(lineas, ruta) do
    archivo = File.open!(ruta, [:write, :utf8])
    escribir(lineas, archivo)
    File.close(archivo)
  end

  defp escribir([], _archivo), do: :ok

  defp escribir([linea | resto], archivo) do
    IO.puts(archivo, linea)
    escribir(resto, archivo)
  end
end
