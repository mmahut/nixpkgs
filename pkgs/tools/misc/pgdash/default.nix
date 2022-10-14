{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "pgdash";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "rapidloop";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-jMjilvqLpf7kCz9UONX9ZRhjR8bt/XyhjXEa1KyZ3MQ=";
  };

  vendorSha256 = "sha256-wzFtdoYIm2Zm5F6+TjDZvMgafBl5YuBX8OH2i5sOfgk=";

  doCheck = false;

  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  meta = with lib; {
    homepage = "https://pgdash.io/";
    description = "Command-line tool for interacting with pgdash.io";
    license = licenses.asl20;
    maintainers = [ maintainers.mmahut ];
  };
}
