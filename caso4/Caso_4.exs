Code.require_file("../FolderComun/Util2.ex")
Code.require_file("../FolderComun/lector.ex")
Code.require_file("../FolderComun/reporte.ex")
Code.require_file("lector_propuestas.ex")
Code.require_file("validador_parentesis.ex")
Code.require_file("lector_parametros.ex")
Code.require_file("generador_parentesis.ex")
Code.require_file("escritor_parentesis.ex")

defmodule Caso4 do
  @doc """
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Orquesta el problema 4:
  1. Validación de propuestas (verificacion_parentesis.txt).
  2. Generación perezosa de soluciones por cada (n,p) de parametros.csv.
  3. Primera solución de n=18, p=18.
  4. Stream infinito de crecimiento (secuencia_parentesis.csv).
  """
  def main(
        archivo_entrada \\ "propuestas.txt",
        archivo_salida \\ "verificacion_parentesis.txt",
        archivo_parametros \\ "parametros.csv"
      ) do
    verificar_propuestas(archivo_entrada, archivo_salida)
    generar_soluciones(archivo_parametros)
    primera_solucion()
    secuencia_infinita()
  end

  # ---- Validación de propuestas (parte de la persona 1) ----
  defp verificar_propuestas(entrada, salida) do
    case LectorPropuestas.leer(entrada) do
      {:error, :no_existe} -> Reporte.archivo_faltante(entrada)
      {:ok, registros} -> procesar_propuestas(registros, salida)
    end
  end

  defp procesar_propuestas(registros, salida) do
    registros
    |> ValidadorParentesis.validar()
    |> ValidadorParentesis.a_lineas()
    |> Reporte.guardar_lineas(salida)

    Util2.mostrar("Verificación terminada. Resultados en #{salida}.", :mensaje)
  end

  # ---- Soluciones por cada (n,p) de parametros.csv ----
  defp generar_soluciones(ruta) do
    case LectorParametros.leer(ruta) do
      {:error, :no_existe} -> Reporte.archivo_faltante(ruta)
      {:ok, flujo} -> Enum.each(flujo, &atender_parametro(&1, ruta))
    end
  end

  defp atender_parametro({:error, linea, motivo}, ruta) do
    Util2.mostrar("Error en #{ruta}, línea #{linea}: #{motivo}", :error)
  end

  defp atender_parametro({:ok, _linea, n, p}, _ruta) do
    archivo = "parentesis_n#{n}_p#{p}.txt"
    total = EscritorParentesis.escribir_soluciones(n, p, archivo)
    Util2.mostrar("n=#{n}, p=#{p}: total #{total} (archivo #{archivo})", :mensaje)
  end

  # ---- Primer elemento de n=18, p=18 ----
  defp primera_solucion do
    ruta = "primera_n18_p18.txt"
    primera = EscritorParentesis.escribir_primera(18, 18, ruta)
    Util2.mostrar("Primera solución n=18, p=18: #{primera} (archivo #{ruta})", :mensaje)
  end

  # ---- Stream infinito de crecimiento ----
  defp secuencia_infinita do
    ruta = "secuencia_parentesis.csv"
    {n, total} = EscritorParentesis.escribir_secuencia(ruta)
    Util2.mostrar("Secuencia detenida en n=#{n} con total #{total} (archivo #{ruta})", :mensaje)
  end
end

case System.argv() do
  [entrada] -> Caso4.main(entrada)
  [entrada, salida] -> Caso4.main(entrada, salida)
  [entrada, salida, parametros] -> Caso4.main(entrada, salida, parametros)
  _ -> Caso4.main()
end
