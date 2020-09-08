{ pkgs ? import <nixpkgs> { config = { allowBroken = true; }; }
, compiler ? "ghc883" }:
let
  fonts = with pkgs; [ source-sans-pro iosevka ];
  githubHaskellPackage = haskellPackages: attrs: args:
    let
      prefetched = builtins.fromJSON (builtins.readFile attrs.path);
      src = builtins.fetchTarball {
        name = "${attrs.repo}";
        url =
          "https://github.com/${attrs.owner}/${attrs.repo}/archive/${prefetched.rev}.git";
        inherit (prefetched) sha256;
      };
      packageSrc =
        if attrs.repoSubDir == "" then src else "${src}/${attrs.repoSubDir}";
    in haskellPackages.callCabal2nix attrs.repo packageSrc args;

  haskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = self: super: {
      pandoc-emphasize-code = githubHaskellPackage self {
        owner = "owickstrom";
        repo = "pandoc-emphasize-code";
        path = ./nix/pandoc-emphasize-code.json;
        repoSubDir = "";
      } { };
    };
  };
  ghc = haskellPackages.ghcWithPackages (p: [ ]);
in pkgs.stdenv.mkDerivation {
  name = "slides";
  src = ./.;
  installPhase = ''
    cp -r target $out
  '';
  buildInputs = with pkgs; [
    nixfmt
    pympress
    pandoc
    texlive.combined.scheme-full
    haskellPackages.pandoc-include-code
    haskellPackages.pandoc-emphasize-code
  ];
  FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = fonts; };
}
