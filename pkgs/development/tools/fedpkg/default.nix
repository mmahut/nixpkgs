{ stdenv, buildPythonApplication, buildPythonPackage, isPy3k, fetchurl, rpkg, offtrac, urlgrabber, pyopenssl, python_fedora, bugzilla, distro, pyyaml, freezegun, nose-cov, mock, koji }:

let
  fedora_cert = buildPythonPackage rec {
    name = "fedora-cert";
    version = "0.6.0.2";
    format = "other";

    src = fetchurl {
      url = "https://releases.pagure.org/fedora-packager/fedora-packager-${version}.tar.bz2";
      sha256 = "02f22072wx1zg3rhyfw6gbxryzcbh66s92nb98mb9kdhxixv6p0z";
    };
    propagatedBuildInputs = [ python_fedora pyopenssl ];
    doCheck = false;
  };
in buildPythonApplication rec {
  pname = "fedpkg";
  version = "1.37";

#  disabled = isPy3k;

  src = fetchurl {
    url = "https://releases.pagure.org/fedpkg/${pname}-${version}.tar.bz2";
    sha256 = "0153sgi9xlbz88x93hw2x5l7aap7291464srs3rc8pkas6d0ajcp";
  };

  patches = [ ./fix-paths.patch ];

  postPatch = ''
      substituteInPlace tests-requirements.txt --replace "mock == 1.0.1" "mock"
      # Removing integration tests
      rm test/test_{retire,cli,commands}.py
   '';

  checkInputs = [ mock ];
  propagatedBuildInputs = [ rpkg offtrac urlgrabber fedora_cert bugzilla distro pyyaml freezegun nose-cov koji ];

  meta = with stdenv.lib; {
    description = "Subclass of the rpkg project for dealing with rpm packaging";
    homepage = "https://pagure.io/fedpkg";
    license = licenses.gpl2;
    maintainers = [ maintainers.mmahut ];
  };
}
