{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    xorg.libX11
    xorg.libXinerama
    xorg.libXft
    xorg.libxcb
    fontconfig
    freetype
    pkg-config
    gnumake
    gcc
    libspng
  ];
}
