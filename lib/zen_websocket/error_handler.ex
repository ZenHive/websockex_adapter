defmodule ZenWebsocket.ErrorHandler do
  @moduledoc """
  Simple error handling for WebSocket connections.

  Handles common error scenarios:
  - Connection errors (network failures)
  - Protocol errors (malformed frames)
  - Authentication errors
  - Timeout errors

  Passes raw errors without wrapping to preserve original error information.
  """

  @doc """
  Categorizes errors into recoverable vs non-recoverable types.

  Returns the raw error unchanged to preserve all original information.
  """
  @spec categorize_error(term()) :: {:recoverable | :fatal, term()}
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def categorize_error(error) do
    case error do
      # Recoverable connection/network errors
      {:error, :econnrefused} -> {:recoverable, error}
      {:error, :timeout} -> {:recoverable, error}
      :timeout -> {:recoverable, {:error, error}}
      {:error, :nxdomain} -> {:recoverable, error}
      {:error, {:tls_alert, _}} -> {:recoverable, error}
      {:error, :enotfound} -> {:recoverable, error}
      {:error, :ehostunreach} -> {:recoverable, error}
      {:error, :enetunreach} -> {:recoverable, error}
      {:gun_down, _, _, reason, _} -> {:recoverable, {:gun_down, reason}}
      {:gun_error, _, _, reason} -> {:recoverable, {:gun_error, reason}}
      :connection_failed -> {:recoverable, error}
      # Fatal protocol/auth errors
      {:error, :invalid_frame} -> {:fatal, error}
      {:error, :frame_too_large} -> {:fatal, error}
      {:error, {:bad_frame, _}} -> {:fatal, error}
      {:error, :unauthorized} -> {:fatal, error}
      {:error, :invalid_credentials} -> {:fatal, error}
      {:error, :token_expired} -> {:fatal, error}
      # Unknown errors are fatal (let higher levels decide whether to crash)
      _ -> {:fatal, error}
    end
  end

  @doc """
  Determines if an error is recoverable through reconnection.
  """
  @spec recoverable?(term()) :: boolean()
  def recoverable?(error) do
    case categorize_error(error) do
      {:recoverable, _} -> true
      {:fatal, _} -> false
    end
  end

  @doc """
  Handles errors by returning appropriate actions.

  Returns either :reconnect or :stop based on error recoverability.
  """
  @spec handle_error(term()) :: :reconnect | :stop
  def handle_error(error) do
    case categorize_error(error) do
      {:recoverable, _} -> :reconnect
      {:fatal, _} -> :stop
    end
  end
end
