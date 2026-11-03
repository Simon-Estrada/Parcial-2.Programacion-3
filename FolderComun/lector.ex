defmodule Lector do

  def lineas_utiles(ruta) do
    if File.exists?(ruta) do
      pasos =
        ruta
        |> File.stream!()
        |> Stream.with_index()
        |> Stream.map(fn {texto, n} -> {n, String.trim(texto)} end)
        |> Stream.reject(fn {_n, texto} ->
          texto == "" or String.starts_with?(texto, "#")
        end)

        {:ok, pasos}
    else
      {:error, "El archivo no existe"}
    end
  end
end
