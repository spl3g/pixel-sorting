{
  description = "An empty flake template that you can adapt to your own environment";

  # Flake inputs
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  # Flake outputs
  outputs = { self, nixpkgs }:
    let
      # The systems supported for this flake
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
      ];

      # Helper to provide system-specific attributes
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            (odin.overrideAttrs(final: prev: {
              preBuild = ''
                pushd vendor/stb/src
                make
                popd
              '';
            }))
            stb
          ];
        };
      });
      packages = forEachSupportedSystem ({ pkgs }: {
        default =
          let
            odin = pkgs.odin.overrideAttrs(final: prev: {
              preBuild = ''
                pushd vendor/stb/src
                make unix
                popd
              '';
            });
          in
            pkgs.stdenv.mkDerivation rec {
              name = "pixsort";
              src = ./.;
              nativeBuildInputs = with pkgs; [
                stb
                clang
              ] ++ [ odin ];
              buildPhase = ''
                odin build . -reloc-mode:pic -build-mode:obj -out:${name}.o
                clang -fPIE ${name}.o -o ${name} -L${odin}/share/vendor/stb/lib -l:stb_image.a  -l:stb_image_write.a -lm
              '';
              installPhase = ''
                mkdir -p $out/bin
                cp pixsort $out/bin
              '';
            };
      });
    };
}
