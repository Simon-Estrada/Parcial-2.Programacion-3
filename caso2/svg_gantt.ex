defmodule SvgGantt do
  @moduledoc """
  Módulo encargado de generar el Diagrama de Gantt en formato SVG para representar
  visualmente el primer plan óptimo de ejecución de tareas.

  Implementa las exigencias del Problema 2:
  - Dibujado del eje horizontal de tiempo proporcional a las duraciones.
  - Distinción visual entre tareas terminadas a tiempo (verde) y fuera de plazo (rojo).
  - Marcación explícita del intervalo [inicio - fin] y el plazo límite de cada tarea.
  - Escritura progresiva del SVG por fragmentos (cumpliendo la Regla 4 del parcial).
  - Escapado de caracteres XML y generación de leyenda explicativa si no existe plan.
  """

  @doc """
  Genera el archivo SVG con el diagrama de Gantt correspondiente al primer plan óptimo.

  ## Parámetros
    - `resultado`: Tupla de retorno de `Planificador.generar_planes/3` o estado final.
    - `tareas`: Lista original de estructuras `%Tarea{}`.
    - `ruta_svg`: Ruta donde se guardará el archivo SVG (por defecto `"mejor_plan.svg"`).

  ## Ejemplo
      iex> SvgGantt.generar_svg(resultado_planificador, tareas, "mejor_plan.svg")
      :ok
  """
  @spec generar_svg(map() | :proyecto_vacio, list(%Tarea{}), String.t()) :: :ok
  def generar_svg(resultado_planificador, tareas, ruta_svg \\ "mejor_plan.svg")

  def generar_svg(:proyecto_vacio, _tareas, ruta_svg) do
    generar_svg_vacio(ruta_svg, "Proyecto vacío: no existen tareas para graficar.")
  end

  def generar_svg(%{contador: 0}, _tareas, ruta_svg) do
    generar_svg_vacio(ruta_svg, "No se encontró ningún plan válido para graficar.")
  end

  def generar_svg(%{mejores_planes: [primer_plan | _]}, tareas, ruta_svg) do
    archivo = File.open!(ruta_svg, [:write, :utf8])

    # Convertir lista de tareas a mapa para búsqueda directa por ID: %{"A" => %Tarea{}}
    mapa_tareas = Map.new(tareas, fn t -> {t.id, t} end)

    # Parámetros geométricos de maquetación (en píxeles)
    margen_izq = 120
    margen_sup = 80
    alto_fila = 45
    ancho_unidad = 40  # 40px equivalen a 1 unidad de tiempo
    alto_barra = 25

    tareas_ordenadas = primer_plan.orden
    num_tareas = length(tareas_ordenadas)
    duracion_total = calcular_duracion_maxima(primer_plan.finalizaciones)

    ancho_total = margen_izq + duracion_total * ancho_unidad + 100
    alto_total = margen_sup + num_tareas * alto_fila + 80

    # 1. Encabezado e instrucciones CSS internas
    IO.write(archivo, """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{ancho_total}" height="#{alto_total}" style="font-family: Arial, sans-serif;">
      <style>
        .titulo { font-size: 18px; font-weight: bold; fill: #2c3e50; }
        .leyenda { font-size: 12px; fill: #333; }
        .eje-texto { font-size: 11px; fill: #7f8c8d; text-anchor: middle; }
        .linea-eje { stroke: #e0e0e0; stroke-dasharray: 4,4; }
        .etiqueta-tarea { font-size: 13px; font-weight: bold; fill: #2c3e50; text-anchor: end; }
        .texto-barra { font-size: 11px; font-weight: bold; fill: #ffffff; text-anchor: middle; }
        .barra-a-tiempo { fill: #2ecc71; rx: 4px; ry: 4px; }
        .barra-tardia { fill: #e74c3c; rx: 4px; ry: 4px; }
      </style>

      <!-- Título y Leyenda -->
      <text x="20" y="30" class="titulo">Diagrama de Gantt - Primer Plan Óptimo</text>
      <rect x="20" y="45" width="15" height="15" class="barra-a-tiempo"/>
      <text x="42" y="57" class="leyenda">A tiempo</text>
      <rect x="120" y="45" width="15" height="15" class="barra-tardia"/>
      <text x="142" y="57" class="leyenda">Fuera de plazo (Mora)</text>
    """)

    # 2. Dibujado de las líneas horizontales y números del eje de tiempo
    dibujar_eje_tiempo(archivo, duracion_total, ancho_unidad, margen_izq, margen_sup, num_tareas * alto_fila)

    # 3. Dibujado progresivo de las barras de tareas
    dibujar_barras_recursivas(
      archivo,
      tareas_ordenadas,
      primer_plan.finalizaciones,
      mapa_tareas,
      margen_izq,
      margen_sup,
      alto_fila,
      ancho_unidad,
      alto_barra,
      0
    )

    # 4. Cierre del documento
    IO.write(archivo, "</svg>\n")
    File.close(archivo)
    :ok
  end

  # ============================================================================
  # Funciones Auxiliares Privadas
  # ============================================================================

  # Genera un SVG alternativo con una leyenda cuando no existen planes válidos
  defp generar_svg_vacio(ruta_svg, mensaje) do
    contenido = """
    <svg xmlns="http://www.w3.org/2000/svg" width="500" height="150" style="font-family: Arial, sans-serif;">
      <rect width="100%" height="100%" fill="#f8f9fa" stroke="#e74c3c" stroke-width="2"/>
      <text x="250" y="80" font-size="16" font-weight="bold" fill="#c0392b" text-anchor="middle">
        #{escapar_xml(mensaje)}
      </text>
    </svg>
    """
    File.write!(ruta_svg, contenido)
    :ok
  end

  # Dibuja la rejilla vertical para representar el avance del tiempo
  defp dibujar_eje_tiempo(archivo, duracion_total, ancho_unidad, margen_izq, margen_sup, alto_contenido) do
    Enum.each(0..duracion_total, fn t ->
      x = margen_izq + t * ancho_unidad
      y_fin = margen_sup + alto_contenido

      IO.write(archivo, """
        <line x1="#{x}" y1="#{margen_sup}" x2="#{x}" y2="#{y_fin}" class="linea-eje"/>
        <text x="#{x}" y="#{y_fin + 20}" class="eje-texto">#{t}h</text>
      """)
    end)
  end

  # Procesa recursivamente la lista ordenada de tareas para imprimir los elementos <rect> y <text>
  defp dibujar_barras_recursivas(
         _archivo,
         [],
         _finalizaciones,
         _mapa_tareas,
         _m_izq,
         _m_sup,
         _a_fila,
         _a_unidad,
         _a_barra,
         _i
       ),
       do: :ok

  defp dibujar_barras_recursivas(
         archivo,
         [id_tarea | resto],
         finalizaciones,
         mapa_tareas,
         m_izq,
         m_sup,
         a_fila,
         a_unidad,
         a_barra,
         indice
       ) do
    tarea = Map.fetch!(mapa_tareas, id_tarea)
    fin = Map.fetch!(finalizaciones, id_tarea)
    inicio = fin - tarea.duracion
    a_tiempo? = fin <= tarea.plazo

    x = m_izq + inicio * a_unidad
    y = m_sup + indice * a_fila + 10
    ancho_barra = tarea.duracion * a_unidad
    clase_barra = if a_tiempo?, do: "barra-a-tiempo", else: "barra-tardia"

    id_escapado = escapar_xml(id_tarea)

    # Escritura progresiva en flujo XML del fragmento de la tarea
    IO.write(archivo, """
      <!-- Tarea #{id_escapado} -->
      <text x="#{m_izq - 15}" y="#{y + 18}" class="etiqueta-tarea">Tarea #{id_escapado}</text>
      <rect x="#{x}" y="#{y}" width="#{ancho_barra}" height="#{a_barra}" class="#{clase_barra}"/>
      <text x="#{x + ancho_barra / 2}" y="#{y + 17}" class="texto-barra">#{inicio}-#{fin} (Plazo: #{tarea.plazo})</text>
    """)

    dibujar_barras_recursivas(
      archivo,
      resto,
      finalizaciones,
      mapa_tareas,
      m_izq,
      m_sup,
      a_fila,
      a_unidad,
      a_barra,
      indice + 1
    )
  end

  # Obtiene la máxima hora de finalización registrada en el mapa
  defp calcular_duracion_maxima(finalizaciones) do
    finalizaciones
    |> Map.values()
    |> Enum.max(fn -> 0 end)
  end

  # Escapa caracteres reservados de XML para prevenir errores de syntaxis gráfica
  defp escapar_xml(texto) do
    texto
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
