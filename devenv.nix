{ pkgs, lib, config, inputs, ... }:

{
  devcontainer.enable = true;
  # https://devenv.sh/languages/
  languages.zig.enable = true;
}
