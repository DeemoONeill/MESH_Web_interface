defmodule MeshServer.Filetypes do
  def get_filetype(filename) do
    case File.open(filename) do
      {:ok, pid} -> read_file(pid)
      {:error, _reason} -> :unknown
    end
  end

  def read_file(pid) do
    IO.binread(pid, 2000)
    |> type
  end

  defp type(binary) do
    case binary do
      # excel, word, zip
      <<?P, ?K, 3, 4, rest::binary>> -> odf_type(rest)
      # empty archive
      <<?P, ?K, 5, 6, _rest::binary>> -> :empty_odf
      # spanned arcive
      <<?P, ?K, 7, 8, _rest::binary>> -> :spanned_odf
      <<?%, ?P, ?D, ?F, ?-, _rest::binary>> -> :pdf
      <<?{, ?r, ?t, ?f, ?1, _rest::binary>> -> :rtf
      <<137, ?P, ?N, ?G, 13, 10, 26, 10, _rest::binary>> -> :png
      <<255, 216, 255, _rest::binary>> -> :jpg
      <<239, 178, 191, _rest::binary>> -> plain_text_type(binary, :utf8)
      # utf-16 little endian
      <<255, 254, _rest::binary>> -> :utf16LE
      # utf-16 big endian
      <<254, 255, _rest::binary>> -> :utf16BE
      # utf-32 little endian
      <<255, 254, 0, 0, _rest::binary>> -> :utf32LE
      # utf-32 big endian
      <<0, 0, 254, 255, _rest::binary>> -> :utf32BE
      _ -> plain_text_type(binary, :utf8)
    end
  end

  defp odf_type(binary) do
    if binary =~ "[Content_Types].xml" do
      if binary =~ "document" do
        :word_document
      else
        :excel_file
      end
    else
      :zip
    end
  end

  defp plain_text_type(binary, encoding) do
    case {binary =~ "{", binary =~ "}", binary =~ "[", binary =~ "]", binary =~ ",",
          binary =~ "|", binary =~ "<xml", binary =~ "<html", binary =~ "</"} do
      {true, true, true, true, true, _, _, _, _} -> {:json, encoding}
      {true, true, false, false, true, _, _, _, _} -> {:json, encoding}
      {false, false, true, true, true, _, _, _, _} -> {:json, encoding}
      {true, true, true, true, false, _, _, _, _} -> {:json, encoding}
      {true, true, false, false, false, _, false, false, false} -> {:json, encoding}
      {_, _, _, _, true, _, false, false, false} -> {:csv, encoding}
      {_, _, _, _, _, true, false, false, false} -> {:psv, encoding}
      {_, _, _, _, _, _, true, false, true} -> {:xml, encoding}
      {_, _, _, _, _, _, false, true, true} -> {:html, encoding}
      {_, _, _, _, _, _, false, false, true} -> {:xml, encoding}
    end
  end
end
