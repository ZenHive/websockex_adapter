defmodule WebsockexAdapter.Test.Support.CertificateHelper do
  @moduledoc """
  Helper for generating self-signed certificates for testing TLS connections.

  This module provides a simple way to generate temporary certificates for testing
  secure connections. It uses Erlang/OTP's public_key module to create self-signed
  certificates that are suitable for test environments.
  """

  require Logger

  @doc """
  Generates a self-signed certificate and key pair for testing.

  Returns a tuple containing `{certfile, keyfile}` where both are temporary file paths
  containing the certificate and private key.

  The files are created in the OS temporary directory and will be cleaned up
  when the BEAM terminates.

  ## Options:

  * `:common_name` - The common name (CN) for the certificate (default: "localhost")
  * `:days` - Validity period in days (default: 365)
  """
  @spec generate_self_signed_certificate(Keyword.t()) :: {String.t(), String.t()}
  def generate_self_signed_certificate(opts \\ []) do
    common_name = Keyword.get(opts, :common_name, "localhost")
    days = Keyword.get(opts, :days, 365)

    Logger.debug("Generating self-signed certificate for testing")

    # Generate a new RSA key pair
    key = X509.PrivateKey.new_rsa(2048)

    # Create the subject/issuer name with CN
    # Generate the certificate
    subject = "/CN=#{common_name}"

    cert =
      X509.Certificate.self_signed(
        key,
        subject,
        template: :server,
        validity: days
      )

    # Encode to PEM format
    key_pem = X509.PrivateKey.to_pem(key)
    cert_pem = X509.Certificate.to_pem(cert)

    # Write to temporary files
    cert_file = write_temp_file("cert-", ".pem", cert_pem)
    key_file = write_temp_file("key-", ".pem", key_pem)

    Logger.debug("Generated test certificate at: #{cert_file}")
    Logger.debug("Generated test private key at: #{key_file}")

    {cert_file, key_file}
  end

  # Write content to a temporary file
  defp write_temp_file(prefix, suffix, content) do
    {:ok, path} = Temp.path(%{prefix: prefix, suffix: suffix})
    :ok = File.write(path, content)
    path
  end
end
