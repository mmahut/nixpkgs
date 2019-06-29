{ stdenv
, fetchFromGitHub
, autoconf
, automake
, python
, pythonPackages
, libtool
, pkg-config
, pam
, qemu }:

stdenv.mkDerivation rec {
  pname = "ovirt-guest-agent";
	version = "1.0.16";

  src = fetchFromGitHub {
		owner = "oVirt";
		repo = pname;
		rev = version;
    sha256 = "1w8j64iysxcwp96k7dspi4kmcjj1xmw5r2222gg3dzmrhqjng7jc";
  };

  preConfigure = ''
    ./autogen.sh
  '';

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    python
    pythonPackages.pycodestyle
    pkg-config
    pam
    qemu
  ];

  configureFlags = [
    "--without-gdm"
    "--without-kdm"
  ];

  meta = with stdenv.lib; {
    description = "Guest Agent for oVirt";
    homepage = "https://www.ovirt.org/";
    license = licenses.asle20;
    maintainers = [ maintainers.mmahut ];
    platforms = platforms.all;
  };
}
