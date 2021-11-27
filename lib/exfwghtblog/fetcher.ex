defmodule Exfwghtblog.Fetcher do
  @moduledoc """
  Constant storage fetch system. Most used with an AWS S3 or Lightsail storage 
  bucket.
  """

  @max_fetch 500 # Has to be <1000 because the first key is always the dirname

  def fetch(path) do
    fetch_p(System.get_env("S3BUCKET") || :local, path)
  end

  def fetch_all(path) do
    fetch_all_p(System.get_env("S3BUCKET") || :local, path)
  end

  defp fetch_p(:local, relative) do
    path = Path.join(Application.app_dir(:exfwghtblog, "priv"), relative)

    case File.read(path) do
      {:ok, data} -> {:ok, :local, data}
      {:error, error} -> {:error, :local, error}
    end
  end

  defp fetch_p(bucket, relative) do
    client = Exfwghtblog.AwsAgent.get()

    case AWS.S3.get_object(client, bucket, Path.relative(relative)) do
      {:ok, response, _body} -> {:ok, :remote, response["Body"]}
      {:error, reason} -> {:error, :remote, reason}
    end
  end

  defp fetch_all_p(:local, relative) do
    path = Path.join(Application.app_dir(:exfwghtblog, "priv"), relative)

    case File.ls(path) do
      {:ok, dirs} ->
        {:ok, :local, dirs |> Enum.take(@max_fetch) |> Enum.map(&Path.basename(&1, ".md"))}

      {:error, error} ->
        {:error, :local, error}
    end
  end

  defp fetch_all_p(bucket, absolute) do
    client = Exfwghtblog.AwsAgent.get()
    relative = Path.relative(absolute)

    case AWS.S3.list_objects_v2(
           client,
           bucket,
           nil,
           nil,
           nil,
           nil,
           @max_fetch,
           relative
         ) do
      {:ok, response, _body} ->
        {:ok, :remote,
         get_in(response, ["ListBucketResult", "Contents"])
         |> Enum.map(&Path.basename(&1["Key"], ".md"))
         |> Enum.reject(&(&1 == relative))}

      {:error, reason} ->
        {:error, :remote, reason}
    end
  end
end
