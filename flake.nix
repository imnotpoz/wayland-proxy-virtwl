{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) ocamlPackages;
        memfd = ocamlPackages.buildDunePackage rec {
          pname = "memfd";
          version = "0.1.0";

          src = pkgs.fetchurl {
            url = "https://github.com/gborough/memfd/releases/download/${version}/memfd-${version}.tbz";
            hash = "sha256-B4rpkPbAkkq/KUaTqR4AxwyQYqklvhgPl97jy6FbuVg=";
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
          ];

          inputsFrom = [
            self.packages.${system}.proxy
          ];
        };

        packages = {
          proxy =
            # Based on build rule in nixpkgs, by qyliss and sternenseemann
            ocamlPackages.buildDunePackage rec {
              pname = "wayland-proxy-virtwl";
              version = "dev";

              src = ./.;

              nativeBuildInputs = [
                pkgs.pkg-config
              ];

              buildInputs = [ pkgs.libdrm ] ++ (with ocamlPackages; [
                dune-configurator
                eio_main
                ppx_cstruct
                xmlm  #wayland    (vendored)
                cmdliner
                logs
                memfd
              ]);
            };

          default = self.packages.${system}.proxy;
        };
      }
    );
}
