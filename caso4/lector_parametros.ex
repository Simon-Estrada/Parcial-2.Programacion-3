defmodule LectorParametros do
  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3

  Lectura perezosa de `parametros.csv`. Cada registro tiene el formato
  `n;profundidad_max` con `n >= 1` y `1 <= profundidad_max <= n`.
  """

  @doc """
  Abre `ruta` como Stream de registros ya interpretados.

  Retorna `{:ok, stream}`, donde cada elemento del stream es
  `{:ok, linea, n, p}` si el registro es correcto o `{:error, linea, motivo}`
  si no lo es, o `{:error, :no_existe}` si el archivo no existe.

  No se materializa ninguna lista: cada registro se valida por pattern
  matching y guards solo cuando se consume el Stream.
  """
  def leer(ruta) do
    case Lector.lineas_utiles(ruta) do
      {:ok, flujo} -> {:ok, Stream.map(flujo, &parsear/1)}
      {:error, :no_existe} -> {:error, :no_existe}
    end
  end

  # parsear/1 separa la línea por ";" y exige exactamente dos campos
  defp parsear({linea, texto}) do
    case String.split(texto, ";") do
      [n, p] -> verificar(linea, Lector.a_entero(n), Lector.a_entero(p))
      campos -> {:error, linea, "se esperaban 2 campos (n;profundidad_max) y hay #{contar(campos)}"}
    end
  end

  # verificar/3: el ORDEN de las cláusulas importa, cada una asume que las anteriores no coincidieron.
  defp verificar(linea, n, p) when not is_integer(n) or not is_integer(p),
    do: {:error, linea, "n y profundidad_max deben ser enteros"}

  defp verificar(linea, n, _p) when n < 1,
    do: {:error, linea, "n debe ser >= 1 (n=#{n})"}

  defp verificar(linea, _n, p) when p < 1,
    do: {:error, linea, "profundidad_max debe ser >= 1 (p=#{p})"}

  defp verificar(linea, n, p) when p > n,
    do: {:error, linea, "profundidad_max no puede superar n (n=#{n}, p=#{p})"}

  defp verificar(linea, n, p), do: {:ok, linea, n, p}

  # Cuenta los elementos de una lista de forma recursiva (sin Enum)
  defp contar([]), do: 0
  defp contar([_ | resto]), do: 1 + contar(resto)
end
