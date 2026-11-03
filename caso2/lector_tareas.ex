defmodule LectorTareas do
  def leer(ruta) do
    case Lector.lineas_utiles(ruta) do
      {:ok, pasos} ->
      registros = pasos |> Stream.map(&parsear/1) |> Enum.to_list()
      {:ok, registros}

      {:error, :no_existe} ->
        {:error, :no_existe}
    end
  end

  defp parsear({linea, texto}) do
    case String.split(texto, ";") do
      [id, duracion, plazo, dependecias] ->
        {:ok, linea,
         %Tarea{
           id: String.trim(id),
           duracion: a_entero(duracion),
           plazo: a_entero(plazo),
           dependencias: parsear_dependencias(dependecias)
         }}

        campos ->
          {:error, linea, "se esperaban 4 campos y se tienen #{length(campos)}"}
    end
  end

  defp parsear_dependencias(texto) do
    case String.trim(texto) do
      "-" -> []
        vacio -> vacio |> String.split(",") |> Enum.map(&String.trim/1)

    end
  end

  defp a_entero(texto) do
    case Integer.parse(String.trim(texto)) do
      {valor, ""} -> valor
       _ -> :invalido
    end
  end
end
