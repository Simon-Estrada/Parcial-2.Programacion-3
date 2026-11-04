defmodule ValidadorParentesis do
  @moduledoc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3

  Validación de propuestas de secuencias de paréntesis leídas desde un archivo de texto.
  No se usa Enum ni Stream dentro de las comprobaciones recursivas para cumplir
  con la regla de aplicar recursividad propia en todo momento.

  """
  @doc """
    Valida la lista de propuestas entregadas por la lectura del archivo.
    Retorna una lista de tuplas con la línea, la cadena original y sus motivos de invalidez.
  """
  # Caso base
  def validar([]), do: []
  # Caso recursivo para líneas con error de lectura/formato previo
  def validar([{:error, linea, motivo} | resto]) do
    [{linea, "(línea mal formada)", [motivo]} | validar(resto)]
  end
  # Caso recursivo principal cuando la línea se leyó correctamente
  def validar([{:ok, linea, n, p, cadena} | resto]) do
    caracteres = String.graphemes(cadena)

    motivos =
      motivo_parametros(n, p) ++
        motivo_longitud(caracteres, n) ++
        motivo_caracteres(caracteres, 0) ++
        motivo_cierre_de_mas(caracteres, 0, "") ++
        motivo_balance_final(caracteres, 0) ++
        motivo_profundidad(caracteres, p)

    [{linea, "#{texto_de(n)};#{texto_de(p)};#{cadena}", motivos} | validar(resto)]
  end

  @doc """
    Convierte el resultado de las validaciones en líneas formateadas de texto
    listas para guardarse en el archivo de reporte.
  """
  # Caso base
  def a_lineas([]), do: []
  # Caso recursivo cuando la propuesta no tuvo ningún motivo de fallo (es válida)
  def a_lineas([{linea, texto, []} | resto]) do
    ["[Línea #{linea}] #{texto} -> VÁLIDA" | a_lineas(resto)]
  end
  # Caso recursivo cuando la propuesta tiene errores (inválida)
  def a_lineas([{linea, texto, motivos} | resto]) do
    ["[Línea #{linea}] #{texto} -> INVÁLIDA" | lineas_de_motivos(motivos)] ++ a_lineas(resto)
  end

  # Funciones privadas auxiliares para formatear la lista de motivos con sangría
  # Caso base
  defp lineas_de_motivos([]), do: []
  # Caso recursivo
  defp lineas_de_motivos([m | resto]), do: ["    - " <> m | lineas_de_motivos(resto)]
  # Verifica que los parámetros n y p sean enteros válidos
  defp motivo_parametros(n, p), do: motivo_entero("n", n) ++ motivo_entero("p", p)

  defp motivo_entero(_nombre, valor) when is_integer(valor), do: []
  defp motivo_entero(nombre, _), do: ["#{nombre} no es un entero válido"]
# Revisa que la longitud de la cadena corresponda a 2 * n
  defp motivo_longitud(_caracteres, n) when not is_integer(n), do: []

  defp motivo_longitud(caracteres, n) do
    largo = contar(caracteres)

    if largo == 2 * n,
      do: [],
      else: ["Longitud incorrecta: tiene #{largo} caracteres y se esperaban #{2 * n}"]
  end
  # Verifica que la cadena contenga únicamente los caracteres '(' y ')'
  # Casos base y de coincidencia correcta
  defp motivo_caracteres([], _pos), do: []
  defp motivo_caracteres(["(" | resto], pos), do: motivo_caracteres(resto, pos + 1)
  defp motivo_caracteres([")" | resto], pos), do: motivo_caracteres(resto, pos + 1)
  # Caso recursivo para detectar un carácter no permitido
  defp motivo_caracteres([otro | _resto], pos) do
    ["Carácter no permitido '#{otro}' en la posición #{pos} (solo se admiten '(' y ')')"]
  end
  # Detecta si se intenta cerrar un paréntesis sin tener uno abierto previamente
  # Caso base
  defp motivo_cierre_de_mas([], _balance, _prefijo), do: []
  # Caso recursivo abriendo paréntesis
  defp motivo_cierre_de_mas(["(" | resto], balance, prefijo) do
    motivo_cierre_de_mas(resto, balance + 1, prefijo <> "(")
  end
  # Caso recursivo cerrando paréntesis: notifica si el balance actual es cero
  defp motivo_cierre_de_mas([")" | resto], balance, prefijo) do
    if balance == 0 do
      ["Se cierra un paréntesis que no estaba abierto. Primer prefijo problemático: \"#{prefijo <> ")"}\""]
    else
      motivo_cierre_de_mas(resto, balance - 1, prefijo <> ")")
    end
  end
  # Caso por si hay caracteres raros para mantener la acumulación del prefijo
  defp motivo_cierre_de_mas([otro | resto], balance, prefijo) do
    motivo_cierre_de_mas(resto, balance, prefijo <> otro)
  end
  # Revisa si la cadena termina con un balance diferente de cero (paréntesis que faltaron cerrar o sobraron)
  defp motivo_balance_final(caracteres, balance) do
    case balance_final(caracteres, balance) do
      0 -> []
      b when b > 0 -> ["No termina con balance cero: quedan #{b} paréntesis sin cerrar"]
      b -> ["No termina con balance cero: se cierran #{-b} paréntesis de más"]
    end
  end
  # Funciones privadas auxiliares para calcular el balance final de forma recursiva
  # Caso base
  defp balance_final([], balance), do: balance
  # Casos recursivos
  defp balance_final(["(" | resto], balance), do: balance_final(resto, balance + 1)
  defp balance_final([")" | resto], balance), do: balance_final(resto, balance - 1)
  defp balance_final([_otro | resto], balance), do: balance_final(resto, balance)
  # Revisa si la cadena supera la profundidad máxima permitida p en algún punto
  defp motivo_profundidad(_caracteres, p) when not is_integer(p), do: []

  defp motivo_profundidad(caracteres, p) do
    case primer_exceso(caracteres, p, 0, "") do
      nil ->
        []

      prefijo ->
        maxima = profundidad_maxima(caracteres, 0, 0)

        ["Excede la profundidad máxima p=#{p}. Primer prefijo problemático: \"#{prefijo}\"; " <>
           "profundidad máxima alcanzada: #{maxima}"]
    end
  end
  # Funciones privadas auxiliares para detectar el primer prefijo que supera p
  defp primer_exceso([], _p, _balance, _prefijo), do: nil

  defp primer_exceso(["(" | resto], p, balance, prefijo) do
    if balance + 1 > p,
      do: prefijo <> "(",
      else: primer_exceso(resto, p, balance + 1, prefijo <> "(")
  end

  defp primer_exceso([otro | resto], p, balance, prefijo) do
    nuevo = if otro == ")", do: balance - 1, else: balance
    primer_exceso(resto, p, nuevo, prefijo <> otro)
  end
  # Calcula la profundidad máxima real alcanzada durante el recorrido completo
  defp profundidad_maxima([], _balance, maxima), do: maxima

  defp profundidad_maxima(["(" | resto], balance, maxima) do
    profundidad_maxima(resto, balance + 1, mayor(balance + 1, maxima))
  end

  defp profundidad_maxima([")" | resto], balance, maxima) do
    profundidad_maxima(resto, balance - 1, maxima)
  end

  defp profundidad_maxima([_otro | resto], balance, maxima) do
    profundidad_maxima(resto, balance, maxima)
  end

 defp texto_de(valor) when is_integer(valor), do: Integer.to_string(valor)
  defp texto_de(_), do: "?"

  defp contar([]), do: 0
  defp contar([_ | resto]), do: 1 + contar(resto)

  defp mayor(a, b) when a > b, do: a
  defp mayor(_a, b), do: b
end
