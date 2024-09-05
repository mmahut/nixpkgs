{
  lib,
  stdenv,
  meson,
  ninja,
  fetchFromGitHub,
  fetchFromGitLab,
  re2c,
  gperf,
  gawk,
  pkg-config,
  boost182,
  fmt,
  luajit_openresty,
  ncurses,
  serd,
  sord,
  libcap,
  liburing,
  openssl,
  cereal,
  cmake,
  asciidoctor,
  makeWrapper,
  gitUpdater
}:

let
  trial-protocol-wrap = fetchFromGitHub {
    owner = "breese";
    repo = "trial.protocol";
    rev = "79149f604a49b8dfec57857ca28aaf508069b669";
    sparseCheckout = [
      "include"
    ];
    hash = "sha256-QpQ70KDcJyR67PtOowAF6w48GitMJ700B8HiEwDA5sU=";
    postFetch = ''
      rm $out/*.*
      mkdir -p $out/lib/pkgconfig
      cat > $out/lib/pkgconfig/trial-protocol.pc << EOF
        Name: trial.protocol
        Version: 0-unstable-2023-02-10
        Description:  C++ header-only library with parsers and generators for network wire protocols
        Requires:
        Libs:
        Cflags:
      EOF
    '';
  };
in
stdenv.mkDerivation rec {
  pname = "emilua";
  version = "0.7.3";

  src = fetchFromGitLab {
    owner = "emilua";
    repo = "emilua";
    rev = "v${version}";
    hash = "sha256-j8ohhqHjSBgc4Xk9PcQNrbADmsz4VH2zCv+UNqiCv4I=";
  };

  buildInputs = [
    luajit_openresty
    boost182
    fmt
    ncurses
    serd
    sord
    libcap
    liburing
    openssl
    cereal
    trial-protocol-wrap
  ];

  nativeBuildInputs = [
    re2c
    gperf
    gawk
    pkg-config
    asciidoctor
    meson
    cmake
    ninja
    makeWrapper
  ];

  dontUseCmakeConfigure = true;

  mesonFlags = [
    (lib.mesonBool "enable_file_io" true)
    (lib.mesonBool "enable_io_uring" true)
    (lib.mesonBool "enable_tests" true)
    (lib.mesonBool "enable_manpages" true)
    (lib.mesonOption "version_suffix" "-nixpkgs1")
  ];

  postPatch = ''
    patchShebangs src/emilua_gperf.awk --interpreter '${lib.getExe gawk} -f'
  '';

  doCheck = true;

  mesonCheckFlags = [
    # Skipped test: libpsx
    # Known issue with no-new-privs disabled in the Nix build environment.
    "--no-suite" "libpsx"
  ];

  passthru.updateScript = gitUpdater {rev-prefix = "v";};

  meta = with lib; {
    description = "Lua execution engine";
    mainProgram = "emilua";
    homepage = "https://emilua.org/";
    license = licenses.boost;
    maintainers = with maintainers; [ manipuladordedados ];
    platforms = platforms.linux;
  };
}
