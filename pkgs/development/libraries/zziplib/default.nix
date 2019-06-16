{ docbook_xml_dtd_412, fetchurl, stdenv, perl, python2, zip, xmlto, zlib, fetchpatch }:

stdenv.mkDerivation rec {
  name = "zziplib-${version}";
  version = "0.13.69";

  src = fetchurl {
    url = "https://github.com/gdraheim/zziplib/archive/v${version}.tar.gz";
    sha256 = "0i052a7shww0fzsxrdp3rd7g4mbzx7324a8ysbc0br7frpblcql4";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/gdraheim/zziplib/commit/f609ae8971f3c0ce64d38276b778001d0bbfc84b.patch";
      sha256 = "0p9s5ix7g98ramf66bf501h08whzd7fanfjp11gyz0manzywghp8";
  })
  ];

  postPatch = ''
    sed -i -e s,--export-dynamic,, configure
  '';

  buildInputs = [ docbook_xml_dtd_412 perl python2 zip xmlto zlib ];

  # tests are broken (https://github.com/gdraheim/zziplib/issues/20),
  # and test/zziptests.py requires network access
  # (https://github.com/gdraheim/zziplib/issues/24)
  doCheck = false;

  meta = with stdenv.lib; {
    description = "Library to extract data from files archived in a zip file";

    longDescription = ''
      The zziplib library is intentionally lightweight, it offers the ability
      to easily extract data from files archived in a single zip
      file.  Applications can bundle files into a single zip archive and
      access them.  The implementation is based only on the (free) subset of
      compression with the zlib algorithm which is actually used by the
      zip/unzip tools.
    '';

    license = with licenses; [ lgpl2Plus mpl11 ];

    homepage = http://zziplib.sourceforge.net/;

    maintainers = [ ];
    platforms = python2.meta.platforms;
  };
}
