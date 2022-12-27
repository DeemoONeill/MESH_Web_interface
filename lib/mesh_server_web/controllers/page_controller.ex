defmodule MeshServerWeb.PageController do
  use MeshServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def inbox(conn, _params) do
    inbox = MeshServer.Directory.Server.get_mailbox({:global, "inbox"})
    render(conn, "inbox.html", inbox: inbox)
  end
end
