defmodule EscritorParentesis do
  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3

  Consume los Streams de `GeneradorParentesis` y escribe los resultados
  progresivamente (una línea por solución), sin acumular las cadenas.
  """

  @doc """
  Escribe en `ruta` una solución por línea conforme el Stream las produce y,
  al final, la línea `Total: N`. Retorna el total.
  """
  def escribir_soluciones(n, p, ruta) do
    archivo = File.open!(ruta, [:write, :utf8])

    total =
      n
      |> GeneradorParentesis.stream(p)
      |> Enum.reduce(0, fn cadena, acumulado ->
        IO.puts(archivo, cadena)
        acumulado + 1
      end)

    IO.puts(archivo, "Total: #{total}")
    File.close(archivo)
    total
  end

  @doc """
  Toma SOLO el primer elemento del Stream de `{n, p}` y lo escribe en `ruta`.
  Gracias a la evaluación perezosa las demás soluciones nunca se calculan.
  """
  def escribir_primera(n, p, ruta) do
    [primera] = n |> GeneradorParentesis.stream(p) |> Enum.take(1)
    archivo = File.open!(ruta, [:write, :utf8])
    IO.puts(archivo, primera)
    File.close(archivo)
    primera
  end

  @doc """
  Stream infinito `{n, total}` con n = 1, 2, 3, ... y p = n.
  Cada total se calcula solo cuando se pide ese elemento.
  """
  def crecimiento do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(fn n -> {n, GeneradorParentesis.contar(n, n)} end)
  end

  @doc """
  Escribe `secuencia_parentesis.csv` (`n;total`) y detiene el consumo justo
  después del primer `n` con total >= `umbral`, incluyéndolo.
  Retorna ese último par `{n, total}`.
  """
  def escribir_secuencia(ruta, umbral \\ 1000) do
    archivo = File.open!(ruta, [:write, :utf8])
    IO.puts(archivo, "n;total")

    ultimo =
      Enum.reduce_while(crecimiento(), nil, fn {n, total} = par, _anterior ->
        IO.puts(archivo, "#{n};#{total}")
        if total >= umbral, do: {:halt, par}, else: {:cont, par}
      end)

    File.close(archivo)
    ultimo
  end
end
