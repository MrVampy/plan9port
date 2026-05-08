# Dev shell for hacking on plan9port — MrVampy/plan9port@wayland.
#
# `nix develop` here drops you into a shell with every build-time dep
# (existing X11/X-perl-which/freetype/fontconfig from the nixpkgs derivation,
# plus the Wayland additions: wayland-scanner, libwayland, wayland-protocols,
# libxkbcommon) plus debugging tools — without polluting the daily-driver
# system. The system itself only consumes the runtime artifacts of a pinned
# commit on this branch (see ~/nix-flake/home/plan9port.nix).
#
# Workflow:
#   cd ~/Tuxedo/plan9port
#   nix develop
#   ./INSTALL -b
#   $PLAN9/bin/acme &
#   ...iterate on src/cmd/devdraw/*, rebuild, retest...
#   git commit; git push origin wayland
#   then bump the rev pin in ~/nix-flake/home/plan9port.nix
#
# This file lives only on the `wayland` branch so `master` stays a pristine
# mirror of 9fans/master.
{
  description = "plan9port dev shell — Tuxedo wayland-on-niri fork";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        # Pull in every build input the nixpkgs plan9port derivation uses
        # — perl, which, fontconfig, freetype, libX11/Xext/Xt, xorgproto,
        # ed — so the X11 build path stays buildable while we work on the
        # Wayland path side-by-side.
        inputsFrom = [ pkgs.plan9port ];

        packages = with pkgs; [
          # Wayland additions for hdonnay's devdraw backend
          wayland          # libwayland-{client,cursor,server}
          wayland-scanner  # protocol code generator (build-time tool)
          wayland-protocols # XML protocol descriptions (xdg-shell, etc.)
          libxkbcommon     # keymap handling
          pkg-config       # devdraw discovers wayland libs via pkg-config

          # Debugging + iteration
          gdb
          clang-tools      # clangd, clang-format
          ripgrep
          fd
          git
        ];

        shellHook = ''
          # Standard plan9port convention: PLAN9 points at the source root
          # so ./INSTALL -b builds in-tree.
          export PLAN9="$PWD"
          export PATH="$PLAN9/bin:$PATH"
          export NAMESPACE="''${XDG_RUNTIME_DIR:-/tmp}/plan9-dev"
          mkdir -p "$NAMESPACE"

          echo "plan9port dev shell — branch $(git branch --show-current)"
          echo "  PLAN9=$PLAN9"
          echo "  NAMESPACE=$NAMESPACE  (isolated from system plumber)"
          echo "  build: ./INSTALL -b"
          echo "  test:  \$PLAN9/bin/acme &"
        '';
      };
    };
}
