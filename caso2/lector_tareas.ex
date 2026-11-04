defmodule LectorTareas do
  @moduledoc """
   ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Modulo funcional que permite leer un csv y convierte cada linea a un %Tarea{}
  """

  @doc """
  Abre la ruta proporcionada usando Stream y devuelve una tupla
  - `{:ok, flujo}` si el archivo existe y se puede leer
  - `{:error, :no_existe}` si el archivo no existe
  """
  def leer(ruta) do
    case Lector.lineas_utiles(ruta) do
      {:ok, flujo} ->
        {:ok, flujo |> Stream.map(&parsear/1) |> Enum.to_list()}

      {:error, :no_existe} ->
        {:error, :no_existe}
    end
  end

  # Convierte la linea de texto dividiendo el ;, dando como resultado una tupla de {:ok, linea, estructura de la tarea}
  # creando un struct %Tarea{} con los datos de la linea, si no cumple con el formato esperado devuelve {:error, linea, mensaje}
  defp parsear({linea, texto}) do
    case String.split(texto, ";") do
      [id, duracion, plazo, dependencias] ->
        {:ok, linea,
         %Tarea{
           id: String.trim(id),
           duracion: Lector.a_entero(duracion),
           plazo: Lector.a_entero(plazo),
           dependencias: parsear_dependencias(dependencias)
         }}

      campos ->
        {:error, linea, "se esperaban 4 campos y hay #{length(campos)}"}
    end
  end
  # Convierte el texto de dependencias en una lista de strings, si es "-" devuelve una lista vacia
  defp parsear_dependencias(texto) do
    case String.trim(texto) do
      "-" -> []
      limpio -> limpio |> String.split("|") |> Enum.map(&String.trim/1)
    end
  end
end
