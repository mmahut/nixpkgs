{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, dpkg
, webkit
, openssl_1_1
}:

stdenv.mkDerivation rec {

  pname = "beersmith";
  version = "3.0.9";

  src = fetchurl {
    url = "https://s3.amazonaws.com/beersmith-3/BeerSmith-${version}_amd64.deb";
    sha256 = "1si1msjmniavlns6n2i9jb7zfv57cg9czpp65nicmvlvi23z88na";
  };

  buildInputs = [
    autoPatchelfHook
    dpkg
    webkit
    openssl_1_1
  ];

  unpackPhase = ''
    mkdir pkg
    dpkg-deb -x $src pkg
    sourceRoot=pkg
  '';

  installPhase = ''
    mkdir -p $out/
    mv usr/ $out/
    find $out
  '';

  meta = with lib; {
    description = "Home brewing software";
    homepage = "http://beersmith.com/";
    maintainers = [ maintainers.mmahut ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
