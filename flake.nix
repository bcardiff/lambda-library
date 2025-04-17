{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/a343533bccc62400e8a9560423486a3b6c11a23b";
    mkshell-minimal.url = "github:viperML/mkshell-minimal";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, mkshell-minimal, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      mkShell = mkshell-minimal pkgs;
    in
    {
      devShell = mkShell {
        buildInputs = with pkgs; [
          ghc
          cabal-install
          haskell-language-server
        ];
      };
    }
  );
}
