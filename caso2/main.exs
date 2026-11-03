Code.require_file("../FolderComun/util2.ex")
Code.require_file("../FolderComun/lector.ex")
Code.require_file("tarea.ex")
Code.require_file("lector_tareas.ex")

ruta = "tareas.csv"

case LectorTareas.leer(ruta) do
  {:ok, registros} -> IO.inspect(registros)
  {:error, _} -> :ok
end
