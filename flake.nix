{
  description = "Brave Origin Nightly binary package";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs:
      let
        pname = "brave-origin-nightly";
        version = "1.93.62";

        src =
          if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
            pkgs.fetchurl {
              url = "https://github.com/brave/brave-browser/releases/download/v${version}/${pname}_${version}_amd64.deb";
              hash = "sha512-rjCrw1t9Itix0zNwlwzyLrAJ3GxCWbIutjoA51NYOb2IpFkaB8A4Uh6s5lOmmdfd4yOjvCxjV7I+ZwgPLO9Bew==";
            }
          else
            pkgs.fetchurl {
              url = "https://github.com/brave/brave-browser/releases/download/v${version}/${pname}_${version}_arm64.deb";
              hash = "sha512-6605a7e8f9e03c2222c5c1e9d7d766ede65cd3d49525a00b92ef970d64a6a4418bdc91358f4337a4e16d84f84e96144165dac26d7f51770a0f93c51f73e492f7";
            };
      in {
        default = pkgs.stdenv.mkDerivation {
          inherit pname version src;

          nativeBuildInputs = with pkgs; [
            dpkg
            autoPatchelfHook
            makeWrapper
          ];

          buildInputs = with pkgs; [
            alsa-lib
            at-spi2-atk
            at-spi2-core
            cairo
            cups
            dbus
            expat
            fontconfig
            freetype
            gcc.cc.lib
            glib
            gtk3
            libdrm
            libgbm
            libGL
            libxkbcommon
            nspr
            nss
            pango
            libx11
            libxcb
            libxcomposite
            libxcursor
            libxdamage
            libxext
            libxfixes
            libxi
            libxrandr
            libxrender
            libxscrnsaver
            libxtst
          ];

          autoPatchelfIgnoreMissingDeps = [
            "libQt5Core.so.5"
            "libQt5Gui.so.5"
            "libQt5Widgets.so.5"
            "libQt6Core.so.6"
            "libQt6Gui.so.6"
            "libQt6Widgets.so.6"
          ];

          unpackPhase = ''
            runHook preUnpack

            ar x $src data.tar.xz
            mkdir unpacked

            tar \
              --no-same-owner \
              --no-same-permissions \
              -xf data.tar.xz \
              -C unpacked

            cp -a unpacked/* .

            rm -rf opt/brave.com/${pname}/cron
            chmod 0755 opt/brave.com/${pname}/chrome-sandbox || true

            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp -a opt usr $out/

            rm -f $out/usr/bin/${pname}

            mkdir -p $out/bin
            makeWrapper $out/opt/brave.com/${pname}/${pname} $out/bin/${pname} \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]} \

            mkdir -p $out/share/pixmaps
            ln -s $out/opt/brave.com/${pname}/product_logo_128_nightly.png \
              $out/share/pixmaps/${pname}.png

            mkdir -p $out/share/applications
            if [ -f $out/usr/share/applications/${pname}.desktop ]; then
              cp $out/usr/share/applications/${pname}.desktop $out/share/applications/${pname}.desktop
              substituteInPlace $out/share/applications/${pname}.desktop \
                --replace "/usr/bin/${pname}" "$out/bin/${pname}" \
                --replace "/opt/brave.com/${pname}/${pname}" "$out/bin/${pname}"
            fi

            runHook postInstall
          '';

          meta = {
            description = "The minimalist browser from the makers of Brave, nightly binary release";
            homepage = "https://brave.com/origin/download-nightly";
            license = pkgs.lib.licenses.mpl20;
            platforms = [ "x86_64-linux" "aarch64-linux" ];
            mainProgram = pname;
          };
        };
      });
  };
}
