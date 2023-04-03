defmodule ProcessHelper do
  def get_name(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} -> name
      _ -> nil
    end
  end

  def get_worker_pid(worker_id) do
    Process.whereis(String.to_atom("TweetPrinter#{worker_id}"))
  end
end
