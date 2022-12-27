defmodule MeshServer.Message do
  @moduledoc """
  Mesh Server.

  Acts as a wrapper around the mesh client file system. This allows reading
  files in, parsing the contents of control files etc.

  """
  alias Swoosh.Adapters.XML
  alias MeshServer.Message

  defstruct [
    :filename,
    :From_DTS,
    :To_DTS,
    :Subject,
    :LocalId,
    :WorkflowId,
    :DTSId,
    :DateTime,
    :Event,
    :Status,
    :Description,
    :data_file,
    :filetype
  ]

  def new(ctl_file) do
    message = %Message{
      (ctl_file
       |> File.read!()
       |> XML.Helpers.parse()
       |> new(__MODULE__.__struct__() |> Map.keys()))
      | filename: ctl_file |> Path.split() |> List.last()
    }

    case dat_file(ctl_file) do
      false ->
        message

      [path, ext] ->
        filename = Path.split(path) |> List.last()

        filename = filename <> ext
        full_path = path <> ext

        %Message{
          message
          | data_file: filename,
            filetype: MeshServer.Filetypes.get_filetype(full_path)
        }
    end
  end

  def new(xml, keys) do
    for key <- keys, into: %Message{} do
      {key, extract_field(key, xml)}
    end
  end

  defp extract_field(key, xml) do
    path = '//#{key}/text()'

    case :xmerl_xpath.string(path, xml) do
      [] ->
        nil

      tuple ->
        tuple
        |> hd
        |> Tuple.to_list()
        |> get_text()
    end
  end

  defp dat_file(filename) do
    data_file = [
      Path.extname(filename)
      |> then(&String.trim(filename, &1)),
      ".dat"
    ]

    if File.exists?(data_file) do
      data_file
    else
      false
    end
  end

  defp get_text([:xmlText | tail]) do
    get_text(tail)
  end

  defp get_text([item, :text]), do: item
  defp get_text([_ | tail]), do: get_text(tail)
  defp get_text([]), do: nil
end

defimpl Collectable, for: MeshServer.Message do
  def into(message) do
    {message, &collector_fun/2}
  end

  defp collector_fun(struct, {:cont, {:__struct__, nil}}), do: struct

  defp collector_fun(struct, {:cont, {key, value}}) when is_atom(key) do
    struct
    |> Map.put(key, value)
  end

  defp collector_fun(struct, :done), do: struct
  defp collector_fun(_struct, :halt), do: :ok
end
