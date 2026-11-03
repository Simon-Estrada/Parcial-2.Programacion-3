defmodule Tarea do
  defstruct [:id, :duracion, :plazo, dependencias: []]
end

defmodule Plan do
  defstruct [:orden, :finalizaciones, :penalizacion]
end
