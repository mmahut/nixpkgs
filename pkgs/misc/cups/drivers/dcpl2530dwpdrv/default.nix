{ pkgsi686Linux, stdenv, fetchurl, dpkg, makeWrapper, coreutils, ghostscript, gnugrep, gnused, which, perl }:

stdenv.mkDerivation rec {
  pname = "dcpl2530dwpdrv";
  version = "4.0.0-1";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf103518/${pname}-${version}.i386.deb";
    sha256 = "1skr6lw8km2lqpjlnkwlrcwjnzrha1y57hzyk0psifz2kv1736bz";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];

  unpackPhase = "dpkg-deb -x $src $out";

  installPhase = ''
    dir=$out/opt/brother/Printers/DCPL2530DW

    substituteInPlace $dir/lpd/lpdfilter \
      --replace /usr/bin/perl ${perl}/bin/perl \
      --replace "BR_PRT_PATH =" "BR_PRT_PATH = \"$dir\"; #" \
      --replace "PRINTER =~" "PRINTER = \"DCPL2530DW\"; #"

    wrapProgram $dir/lpd/lpdfilter \
      --prefix PATH : ${stdenv.lib.makeBinPath [
        coreutils ghostscript gnugrep gnused which
      ]}

    # need to use i686 glibc here, these are 32bit proprietary binaries
    interpreter=${pkgsi686Linux.glibc}/lib/ld-linux.so.2
    patchelf --set-interpreter "$interpreter" $dir/inf/braddprinter
    patchelf --set-interpreter "$interpreter" $dir/lpd/brprintconflsr3
    patchelf --set-interpreter "$interpreter" $dir/lpd/rawtobr3
  '';

  meta = {
    description = "Brother DCPL2530DW lpr driver";
    homepage = http://www.brother.com/;
    license = stdenv.lib.licenses.unfree;
    platforms = [ "x86_64-linux" "i686-linux" ];
    maintainers = [ stdenv.lib.maintainers.enzime ];
  };
}
