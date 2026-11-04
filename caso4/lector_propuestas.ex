defmodule LectorPropuestas do
  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Módulo para leer propuestas de un archivo de texto.
  Cada línea del archivo debe tener el formato: n;p;cadena
  """
  @doc """
  Lee `propuestas.txt` (formato `n;p;cadena`) con Streams.
  """
  def leer(ruta) do
    case Lector.lineas_utiles(ruta) do
      {:ok, flujo} ->
        {:ok, flujo |> Stream.map(&parsear/1) |> Enum.to_list()}

      {:error, :no_existe} ->
        {:error, :no_existe}
    end
  end
  # parsear/1 convierte una línea de texto en una tupla {:ok, linea, n, p, cadena} o {:error, linea, mensaje}
  defp parsear({linea, texto}) do
    case String.split(texto, ";") do
      [n, p, cadena] ->
        {:ok, linea, Lector.a_entero(n), Lector.a_entero(p), String.trim(cadena)}

      campos ->
        {:error, linea, "se esperaban 3 campos (n;p;cadena) y hay #{length(campos)}"}
    end
  end
end
