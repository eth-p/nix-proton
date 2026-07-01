# Fetcher for downloading prebuilt binary packages from GitHub.
{
  fetchurl,
  withMirror ? "https://github.com",
}:
{
  repo,
  release,
  file,
  sha256,
}:
fetchurl {
  inherit sha256;
  url = "${withMirror}/${repo}/releases/download/${release}/${file}";
}
