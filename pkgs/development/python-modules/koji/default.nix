{ stdenv, fetchurl, buildPythonPackage, pycurl, six, rpm, dateutil }:

buildPythonPackage rec {
  pname = "koji";
  version = "1.17.0";
  format = "other";

  src = fetchurl {
    url = "https://releases.pagure.org/koji/${pname}-${version}.tar.bz2";
    sha256 = "0pzhcmgb3wwx16qz3b7r1y8c04raw5zn0ham2dc8lmmpxkiq668j";
  };

#  postPatch = ''
#    substituteInPlace requirements/pypi.txt --replace "koji >= 1.15" "koji"
#    '';

  propagatedBuildInputs = [ pycurl six rpm dateutil ];

  makeFlags = "DESTDIR=$(out)";

  postInstall = ''
    mv $out/usr/* $out/
    cp -R $out/nix/store/*/* $out/
    rm -rf $out/nix
  '';

  meta = with stdenv.lib; {
    description = "RPM building and tracking system";
    homepage = "https://docs.pagure.org/koji/";
    license = licenses.lgpl2;
    maintainers = [ maintainers.mmahut ];
  };

}
