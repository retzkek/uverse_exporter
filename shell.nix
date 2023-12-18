{ pkgs ? import <nixpkgs> {  } }:

let
  customPython = pkgs.python311.buildEnv.override {
    extraLibs = [ 
      pkgs.python311Packages.beautifulsoup4
      pkgs.python311Packages.requests
      pkgs.python311Packages.prometheus-client
    ];
  };
in

pkgs.mkShell {
  buildInputs = [ customPython ];
}
