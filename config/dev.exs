# Developers should use priv as a testbed
import Config

config :exfwghtblog,
  port: 8080,
  # `:local` for local in priv, or a string for a real AWS S3 bucket ID
  bucket: :local,
  bucket_loc: nil, # S3 Bucket Region
  bucket_idx: nil, # S3 Bucket Access ID
  bucket_key: nil  # S3 Bucket Secret Key

