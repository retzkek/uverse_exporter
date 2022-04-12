{ nixpkgs ? import <nixpkgs> {}, pythonPkgs ? nixpkgs.pkgs.python38Packages }:

let
  # This takes all Nix packages into this scope
  inherit (nixpkgs) pkgs;
  # This takes all Python packages from the selected version into this scope.
  inherit pythonPkgs;

  # Inject dependencies into the build function
  f = { buildPythonPackage, beautifulsoup4, requests, prometheus-client }:
    buildPythonPackage rec {
      pname = "uverse-exporter";
      version = "0.1.0";

      # If you have your sources locally, you can specify a path
      src = /home/kretzke/src/uverse_exporter;

      # Pull source from a Git server. Optionally select a specific `ref` (e.g. branch),
      # or `rev` revision hash.
      #src = builtins.fetchGit {
      #  url = "git://github.com/stigok/ruterstop.git";
      #  ref = "master";
      #  #rev = "a9a4cd60e609ed3471b4b8fac8958d009053260d";
      #};

      # Specify runtime dependencies for the package
      propagatedBuildInputs = [ beautifulsoup4 requests prometheus-client];

      # If no `checkPhase` is specified, `python setup.py test` is executed
      # by default as long as `doCheck` is true (the default).
      # I want to run my tests in a different way:
      #checkPhase = ''
      #  python -m unittest tests/*.py
      #'';

      # Meta information for the package
      meta = {
        description = ''
          AT&T Uverse broadband metrics exporter for Prometheus
        '';
      };
    };

  drv = pythonPkgs.callPackage f {};
in
  drv
