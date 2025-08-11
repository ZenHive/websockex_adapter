require Logger
## Configure Logger to only show warnings and errors
# Logger.configure(level: :none)
Logger.configure(level: :info)
# Logger.configure(level: :warning)
# Logger.configure(level: :debug)

ExUnit.start(exclude: [:stability, :stability_dev])
# Display testing policy message
Logger.warning("""
\n[!] TESTING POLICY [!]
--------------------------------------------------
DO NOT USE MOCKS! They are proven to be unreliable.
ALWAYS test against real test APIs (e.g., test.deribit.com).
If no test API is available, use real API.

NEVER SKIP TESTS because you can not find CREDENTIALS. Credentials
must be always present. LET THEM FAIL.

Failure to adhere to this policy will result in immediate
TERMINATION ("you are fired!") and your employment will be terminated.
--------------------------------------------------
\n
""")

# ZenWebsocket uses a simpler architecture without complex behaviors
# Only mock what's actually needed for testing

# Mox.set_mox_global()

### see in mix.exs where it is loaded already
# ["#{__DIR__}", "support/**/*.ex"]
# |> Path.join()
# |> Path.wildcard()
# |> Enum.each(&Code.require_file/1)
### end of see in mix.exs where it is loaded already
