{ pkgs ? import <nixpkgs> {} }:
let
  swift = pkgs.swift;
  xtoolImage = pkgs.fetchurl (if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then {
    url = "https://github.com/xtool-org/xtool/releases/download/1.24.0/xtool-x86_64.AppImage";
    sha256 = "dbfd9d7216f077c84c171b688c4173c37c23ca76bf7fd185d1a9ae8a53dab59f";
  } else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then {
    url = "https://github.com/xtool-org/xtool/releases/download/1.24.0/xtool-aarch64.AppImage";
    sha256 = "4bc0515fed71efb86e82564f358efa0c4c6d76bf1bcfd4c5f256727b53ec59c8";
  } else throw "This shell targets x86_64-linux or aarch64-linux.");
  xtool = pkgs.appimageTools.wrapType2 {
    pname = "xtool";
    version = "1.24.0";
    src = xtoolImage;
  };
in pkgs.mkShell {
  packages = [ swift xtool pkgs.libimobiledevice pkgs.usbmuxd pkgs.sqlite.dev pkgs.sqlite pkgs.git pkgs.curl pkgs.unzip ];
  shellHook = ''
    echo "Social: nixpkgs Swift ${swift.version}; xtool 1.24.0 expects Swift 6.4.x for iOS."
    echo "Run bin/doctor to check this shell, or see README.md for the container route."
  '';
}
