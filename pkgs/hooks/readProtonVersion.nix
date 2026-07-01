# Fetcher for downloading prebuilt binary packages from GitHub.
{
  makeSetupHook,
}:makeSetupHook {
  name = "my-custom-hook";
  
  # Optional: Pass setup variables into the script using substituteAll
  substitutions = {
    # placeholder = "value"; 
  };
} ./my-hook.sh
