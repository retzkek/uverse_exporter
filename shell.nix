{ pkgs ? import <nixpkgs> {  } }:

let
  customPython = pkgs.python38.buildEnv.override {
    extraLibs = [ 
      pkgs.python38Packages.beautifulsoup4
      pkgs.python38Packages.requests
      pkgs.python38Packages.prometheus-client
    ];
  };
in

pkgs.mkShell {
  buildInputs = [ customPython ];
}
