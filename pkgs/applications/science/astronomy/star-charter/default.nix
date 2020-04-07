{ stdenv, fetchFromGitHub, gsl, cairo
}:

stdenv.mkDerivation rec {
  pname = "star-charter";
  version = "unstable-2020-04-06";

  src = fetchFromGitHub {
    owner = "dcf21";
    repo = pname;
    rev = "48881cf85fb981b7969b7015300130a0ab546fb2";
    sha256 = "0ia494972zkixf045xy2gpsfklqc8dyj0pw4la3d3akcd0k1ggbm";
  };

  buildInputs = [ gsl cairo ];

  installPhase = ''
  mkdir -p $out/bin/ $out/share/doc
  cp -rv ./bin/starchart.bin $out/bin/starcharter
  ln -s $out/bin/starcharter $out/bin/StarCharter
  cp -rv examples/ $out/share/doc
  '';


  meta = with stdenv.lib; {
    description = "Free open-source planetarium";
    homepage = http://stellarium.org/;
    license = licenses.gpl2;
    maintainers = with maintainers; [ peti ma27 ];
  };
}
