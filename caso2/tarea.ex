defmodule Tarea do
  @moduledoc "
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Una tarea del proyecto. `dependencias` es una lista de IDs."
  defstruct [:id, :duracion, :plazo, dependencias: []]
end

defmodule Plan do
  @moduledoc "
  ##informacion del proyecto
  - autor: Simon Lopez E, Luna Sofia Oviedo Rios, David Alejandro Henao Jaramillo
  - fecha: noviembre del 2026
  - licencia: GNU GPL v3
  Un plan de ejecución. `finalizaciones` es una lista de IDs de tareas que se completan en este plan."
  defstruct [:orden, :finalizaciones, :penalizacion]
end
