defmodule MeshServer.Directory do
  alias MeshServer.Directory
  defstruct folder: "", messages: [], filenames: MapSet.new()

  def new(path) do
    messages =
      path
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".ctl"))
      |> get_messages(path)

    %Directory{
      folder: path,
      messages: messages,
      filenames: Enum.map(messages, & &1.filename) |> MapSet.new()
    }
  end

  @spec update(%Directory{
          filenames: MapSet.t(),
          folder: binary,
          messages: list(MeshServer.Message)
        }) :: %Directory{
          filenames: MapSet.t(),
          folder: binary,
          messages: list(MeshServer.Message)
        }
  def update(%Directory{} = directory) do
    files =
      directory.folder
      |> File.ls!()
      |> Enum.filter(
        &(String.ends_with?(&1, ".ctl") and not MapSet.member?(directory.filenames, &1))
      )

    messages = get_messages(files, directory.folder) ++ directory.messages

    %Directory{
      directory
      | messages: messages,
        filenames:
          files
          |> MapSet.new()
          |> MapSet.union(directory.filenames)
    }
  end

  defp get_messages(filenames, path) do
    filenames
    |> Enum.map(fn file ->
      Task.async(fn -> MeshServer.Message.new(Path.join(path, file)) end)
    end)
    |> Enum.map(&Task.await/1)
  end
end
