defmodule GeneradorParentesis do
  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3

  Generador recursivo y perezoso de cadenas de paréntesis balanceados con
  profundidad máxima `p`. Nunca construye una lista con todas las soluciones:
  devuelve un Stream que produce cada cadena solo cuando alguien la consume.
  """

  @doc """
  Retorna un Stream con todas las cadenas balanceadas de `n` pares de paréntesis
  cuya profundidad (paréntesis abiertos pendientes) nunca supera `p`.

  El orden es el de intentar primero `(` y luego `)`.

  ## Ejemplo

      iex> GeneradorParentesis.stream(3, 2) |> Enum.to_list()
      ["(()())", "(())()", "()(())", "()()()"]
  """
  def stream(n, p) when is_integer(n) and n >= 1 and is_integer(p) and p >= 1 do
    generar(n, n, 0, p, "")
  end

  @doc """
  Cuenta las soluciones de `{n, p}` consumiendo el Stream sin guardarlas.
  """
  def contar(n, p) do
    n |> stream(p) |> Enum.reduce(0, fn _cadena, acumulado -> acumulado + 1 end)
  end

  # generar(por_abrir, por_cerrar, balance, p, prefijo)
  # Caso base: ya no queda nada por abrir ni cerrar, el prefijo es una solución.
  defp generar(0, 0, _balance, _p, prefijo), do: [prefijo]

  # Caso recursivo: cada opción válida se expande dentro de flat_map, es decir,
  # solo cuando el consumidor pide más elementos (evaluación perezosa).
  defp generar(por_abrir, por_cerrar, balance, p, prefijo) do
    Stream.flat_map(opciones(por_abrir, balance, p), fn
      :abrir -> generar(por_abrir - 1, por_cerrar, balance + 1, p, prefijo <> "(")
      :cerrar -> generar(por_abrir, por_cerrar - 1, balance - 1, p, prefijo <> ")")
    end)
  end

  # "(" primero y ")" después. Solo se ofrece lo que respeta balance y profundidad.
  defp opciones(por_abrir, balance, p) do
    abrir = if por_abrir > 0 and balance < p, do: [:abrir], else: []
    cerrar = if balance > 0, do: [:cerrar], else: []
    abrir ++ cerrar
  end
end
