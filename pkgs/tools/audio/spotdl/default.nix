{ lib
, python3
, fetchFromGitHub
, ffmpeg
}:

python3.pkgs.buildPythonApplication rec {
  pname = "spotdl";
  version = "3.9.0";

  src = fetchFromGitHub {
    owner = "spotDL";
    repo = "spotify-downloader";
    rev = "v${version}";
    sha256 = "sha256-UG1Nmn+W9MdTQP7U4KRo7MxD6mWJhIcg3xwadB0pons=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    spotipy
    pytube
    rich
    rapidfuzz
    mutagen
    ytmusicapi
    tqdm
    beautifulsoup4
    requests
    unidecode
    youtube-dl
    yt-dlp
  ];

  pythonImportsCheck = [
    "rapidfuzz.cpp_process"
  ];

  checkInputs = with python3.pkgs; [
    pytestCheckHook
    pytest-mock
    pytest-vcr
    pyfakefs
    pytest-subprocess
  ];

  # requires networking
  doCheck = false;

  makeWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ ffmpeg ])
  ];

  meta = with lib; {
    description = "Download your Spotify playlists and songs along with album art and metadata";
    homepage = "https://github.com/spotDL/spotify-downloader";
    license = licenses.mit;
    maintainers = with maintainers; [ dotlambda ];
  };
}
