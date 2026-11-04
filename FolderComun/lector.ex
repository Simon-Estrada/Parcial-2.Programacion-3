defmodule Lector do
  @moduledoc """
   ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Lectura perezosa de archivos de texto, compartida por los casos 2 y 4.

  Entrega las líneas útiles (sin vacías ni comentarios `#`) junto con su
  número de línea física, para poder reportar errores con su ubicación.
  """

  @doc """
  Abre `ruta` como Stream de líneas útiles.

  Retorna `{:ok, stream}`, donde cada elemento del stream es
  `{numero_linea, texto}` (la numeración empieza en 1), o
  `{:error, :no_existe}` si el archivo no existe.
  """
  def lineas_utiles(ruta) do
    if File.exists?(ruta) do
      flujo =
        ruta
        |> File.stream!()
        |> Stream.with_index(1)
        |> Stream.map(fn {texto, n} -> {n, String.trim(texto)} end)
        |> Stream.reject(fn {_n, texto} ->
          texto == "" or String.starts_with?(texto, "#")
        end)

      {:ok, flujo}
    else
      {:error, :no_existe}
    end
  end

  @doc """
  Convierte un texto en entero. Retorna el entero o `:invalido`
  (por ejemplo "3x", "" o "abc" dan `:invalido`).
  """
  def a_entero(texto) do
    case Integer.parse(String.trim(texto)) do
      {valor, ""} -> valor
      _ -> :invalido
    end
  end
end
