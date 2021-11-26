import Config

config :exfwghtblog,
  bucket: System.get_env("S3BUCKET") || :local,
  bucket_loc: System.get_env("S3BUCKET_LOC"),
  bucket_idx: System.get_env("S3BUCKET_IDX"),
  bucket_key: System.get_env("S3BUCKET_KEY")

