{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  pkg-config,
  audiofile,
  SDL2,
  libglvnd,
  libX11,
  libxrandr,
  libusb1,
  makeWrapper,
  hexdump,
  sm64baserom,
  region ? "us",
}:

let
  baseRom = (sm64baserom.override { inherit region; }).romPath;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "sm64plus";
  version = "0-unstable-2026-3-10";

  src = fetchFromGitHub {
    owner = "MorsGames";
    repo = "sm64plus";
    rev = "44fccee2fc4bd4768ae4eff1e5c47b21abe5d85d";
    hash = "sha256-hFYzT7QzRL87dral2E/K+zyBeAtK2i4d6Dk4Lt5ii2I=";
  };

  nativeBuildInputs = [
    python3
    pkg-config
    hexdump
    makeWrapper
  ];

  buildInputs = [
    audiofile
    SDL2
    libglvnd
    libX11
    libxrandr
    libusb1
  ];

  postPatch = ''
    substituteInPlace src/pc/gfx/gfx_opengl.c \
      --replace-fail "#include <SDL2/SDL_opengles2.h>" "#include <GL/gl.h>
        #include <GL/glext.h>"
  '';

  enableParallelBuilding = true;
  hardeningDisable = [ "fortify" ];

  makeFlags = [
    "VERSION=${region}"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "OSX_BUILD=1"
  ];

  preBuild = ''
    patchShebangs extract_assets.py
    ln -s ${baseRom} ./baserom.${region}.z64
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/sm64plus

    cp -r build/${region}_pc/gfx $out/share/sm64plus/gfx

    cp build/${region}_pc/sm64.${region} $out/bin/sm64ex_unwrapped

    makeWrapper $out/bin/sm64ex_unwrapped $out/bin/sm64ex \
      --add-flags "$out/share/sm64plus/gfx"

    runHook postInstall
  '';

  meta = {
    description = "Super Mario 64 port based off of decompilation";
    longDescription = ''
      Note that you must supply a baserom yourself to extract assets from.
      If you are not using an US baserom, you must overwrite the "region" attribute with either "eu" or "jp".
      If you would like to use patches sm64ex distributes as makeflags, add them to the "compileFlags" attribute.
    '';
    mainProgram = "sm64ex";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ mochienya ];
    platforms = lib.platforms.unix;
  };
})
