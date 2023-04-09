defmodule ProcessHelper do
  def get_name(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} -> name
      _ -> nil
    end
  end

  def get_worker_pid(worker_type, worker_id) do
    worker_name = Module.split(worker_type) |> List.last()
    Process.whereis(String.to_atom("#{worker_name}#{worker_id}"))
  end
end
