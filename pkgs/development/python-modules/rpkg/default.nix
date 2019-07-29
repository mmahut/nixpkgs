{ stdenv, buildPythonPackage, isPy3k, fetchurl, six, pycurl, cccolutils
, koji, rpmfluff, pyyaml }:

buildPythonPackage rec {
  pname = "rpkg";
  version = "1.58";
  name  = "${pname}-${version}";

  disabled = isPy3k;

  src = fetchurl {
    url = "https://releases.pagure.org/rpkg/${name}.tar.gz";
    sha256 = "1sb4psjlfd8qrcwyg56smiwx1sp5ks0i8zd101jcadq2a4b84jcf";
  };

  propagatedBuildInputs = [ pycurl koji cccolutils six rpmfluff pyyaml ];

  doCheck = false; # needs /var/lib/rpm database to run tests

  meta = with stdenv.lib; {
    description = "Python library for dealing with rpm packaging";
    homepage = https://pagure.io/fedpkg;
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.mmahut ];
  };

}
