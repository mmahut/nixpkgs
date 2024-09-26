{ lib
, buildGoModule
, bzip2
, fetchFromGitHub
, lz4
, nixosTests
, pkg-config
, rocksdb_7_10
, snappy
, stdenv
, zeromq
, zlib
}:

let
  rocksdb = rocksdb_7_10;
in
buildGoModule rec {
  pname = "blockbook";
  version = "unstable";
  commit = "1c70a269";

  src = fetchFromGitHub {
    owner = "trezor";
    repo = "blockbook";
    rev = "1c70a269b0e4902e2f654a2727b6c7df5ee0eb59";
    hash = "sha256-439+eJzTfI1hRZ1sOnzSh4HZQ0Bj8JWtY/fWqJXQ+h4=";
  };

  proxyVendor = true;

  vendorHash = "sha256-P/WwSvlr4LaWR++bNxeRgUO1IwVEsxHKVK6xLbuFbug=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ bzip2 lz4 rocksdb snappy zeromq zlib ];

  ldflags = [
    "-X github.com/trezor/blockbook/common.version=${version}"
    "-X github.com/trezor/blockbook/common.gitcommit=${commit}"
    "-X github.com/trezor/blockbook/common.buildDate=unknown"
  ];

  tags = [ "rocksdb_7_10" ];

  CGO_LDFLAGS = [
    "-L${stdenv.cc.cc.lib}/lib"
    "-lrocksdb"
    "-lz"
    "-lbz2"
    "-lsnappy"
    "-llz4"
    "-lm"
    "-lstdc++"
  ];

  preBuild = lib.optionalString stdenv.isDarwin ''
    ulimit -n 8192
  '';

  subPackages = [ "." ];

  postInstall = ''
    mkdir -p $out/share/
    cp -r $src/static/templates/ $out/share/
    cp -r $src/static/css/ $out/share/
  '';

  passthru.tests = {
    smoke-test = nixosTests.blockbook-frontend;
  };

  meta = with lib; {
    description = "Trezor address/account balance backend";
    homepage = "https://github.com/trezor/blockbook";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ mmahut _1000101 ];
    platforms = platforms.unix;
    mainProgram = "blockbook";
  };
}
