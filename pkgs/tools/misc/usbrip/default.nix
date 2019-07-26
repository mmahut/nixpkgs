{ stdenv
, python3Packages
}:


with python3Packages;

buildPythonApplication rec {
  pname = "usbrip";
  version = "2.1.3.post2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0wxpzrac9xb3x4sc4lr7x2znjhp53bhvzy10c1digrk79zp9pn8b";
  };

  propagatedBuildInputs = [
    termcolor terminaltables wheel
  ];

  patchPhase = ''
        substituteInPlace setup.py --replace "os.path.join(sys.executable.rsplit('/', 1)[0], 'pip')" "'${pip}/bin/pip'"
    '';

    installPhase = ''
      find
    python setup.py install --prefix="$out"
  '';


  meta = with stdenv.lib; {
    description = "Simple command line forensics tool for tracking USB device artifacts";
    homepage = "https://github.com/snovvcrash/usbrip";
    license = licenses.gpl3;
    maintainers = with maintainers; [ tadeokondrak ];
    platforms = platforms.all;
  };
}
