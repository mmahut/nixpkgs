{ stdenv, lib, fetchurl, fetchpatch, fetchFromGitHub, bash, pkg-config, autoconf, cpio
, file, which, unzip, zip, perl, cups, freetype, harfbuzz, alsa-lib, libjpeg, giflib
, libpng, zlib, lcms2, libX11, libICE, libXrender, libXext, libXt, libXtst
, libXi, libXinerama, libXcursor, libXrandr, fontconfig, openjdk17-bootstrap
, setJavaClassPath
, headless ? false
, enableJavaFX ? false, openjfx
, enableGtk ? true, gtk3, glib
}:

let
  version = {
    feature = "17";
    interim = ".0.11";
    build = "9";
  };

  # when building a headless jdk, also bootstrap it with a headless jdk
  openjdk-bootstrap = openjdk17-bootstrap.override { gtkSupport = !headless; };

  openjdk = stdenv.mkDerivation {
    pname = "openjdk" + lib.optionalString headless "-headless";
    version = "${version.feature}${version.interim}+${version.build}";

    src = fetchFromGitHub {
      owner = "openjdk";
      repo = "jdk${version.feature}u";
      rev = "jdk-${version.feature}${version.interim}+${version.build}";
      sha256 = "sha256-aO4iSc9MklW/4q9U86WEfiiWnlq6iZSbxzq2fbsqd0A=";
    };

    nativeBuildInputs = [ pkg-config autoconf unzip ];
    buildInputs = [
      cpio file which zip perl zlib cups freetype harfbuzz alsa-lib libjpeg giflib
      libpng zlib lcms2 libX11 libICE libXrender libXext libXtst libXt libXtst
      libXi libXinerama libXcursor libXrandr fontconfig openjdk-bootstrap
    ] ++ lib.optionals (!headless && enableGtk) [
      gtk3 glib
    ];

    patches = [
      ./fix-java-home-jdk10.patch
      ./read-truststore-from-env-jdk10.patch
      ./currency-date-range-jdk10.patch
      ./increase-javadoc-heap-jdk13.patch
      ./ignore-LegalNoticeFilePlugin-jdk17.patch
      ./fix-library-path-jdk17.patch

      # -Wformat etc. are stricter in newer gccs, per
      # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79677
      # so grab the work-around from
      # https://src.fedoraproject.org/rpms/java-openjdk/pull-request/24
      (fetchurl {
        url = "https://src.fedoraproject.org/rpms/java-openjdk/raw/06c001c7d87f2e9fe4fedeef2d993bcd5d7afa2a/f/rh1673833-remove_removal_of_wformat_during_test_compilation.patch";
        sha256 = "082lmc30x64x583vqq00c8y0wqih3y4r0mp1c4bqq36l22qv6b6r";
      })

      # Patch borrowed from Alpine to fix build errors with musl libc and recent gcc.
      # This is applied anywhere to prevent patchrot.
      (fetchurl {
        url = "https://git.alpinelinux.org/aports/plain/community/openjdk17/FixNullPtrCast.patch?id=41e78a067953e0b13d062d632bae6c4f8028d91c";
        sha256 = "sha256-LzmSew51+DyqqGyyMw2fbXeBluCiCYsS1nCjt9hX6zo=";
      })

      # Fix build for gnumake-4.4.1:
      #   https://github.com/openjdk/jdk/pull/12992
      (fetchpatch {
        name = "gnumake-4.4.1";
        url = "https://github.com/openjdk/jdk/commit/9341d135b855cc208d48e47d30cd90aafa354c36.patch";
        hash = "sha256-Qcm3ZmGCOYLZcskNjj7DYR85R4v07vYvvavrVOYL8vg=";
      })

      # Backport fixes for musl 1.2.4 which are already applied in jdk21+
      # Fetching patch from chimera because they already went through the effort of rebasing it onto jdk17
      (fetchurl {
        name = "lfs64.patch";
        url = "https://raw.githubusercontent.com/chimera-linux/cports/4614075d19e9c9636f3f7e476687247f63330a35/contrib/openjdk17/patches/lfs64.patch";
        hash = "sha256-t2mRbdEiumBAbIAC0zsJNwCn59WYWHsnRtuOSL6bWB4=";
      })
    ] ++ lib.optionals (!headless && enableGtk) [
      ./swing-use-gtk-jdk13.patch
    ];

    postPatch = ''
      chmod +x configure
      patchShebangs --build configure
    '';

    # JDK's build system attempts to specifically detect
    # and special-case WSL, and we don't want it to do that,
    # so pass the correct platform names explicitly
    configurePlatforms = ["build" "host"];

    configureFlags = [
      "--with-boot-jdk=${openjdk-bootstrap.home}"
      "--with-version-build=${version.build}"
      "--with-version-opt=nixos"
      "--with-version-pre="
      "--enable-unlimited-crypto"
      "--with-native-debug-symbols=internal"
      "--with-freetype=system"
      "--with-harfbuzz=system"
      "--with-libjpeg=system"
      "--with-giflib=system"
      "--with-libpng=system"
      "--with-zlib=system"
      "--with-lcms=system"
      "--with-stdc++lib=dynamic"
    ]
    ++ lib.optionals stdenv.cc.isClang [
      "--with-toolchain-type=clang"
      # Explicitly tell Clang to compile C++ files as C++, see
      # https://github.com/NixOS/nixpkgs/issues/150655#issuecomment-1935304859
      "--with-extra-cxxflags=-xc++"
    ]
    ++ lib.optional headless "--enable-headless-only"
    ++ lib.optional (!headless && enableJavaFX) "--with-import-modules=${openjfx}";

    separateDebugInfo = true;

    env.NIX_CFLAGS_COMPILE = "-Wno-error";

    NIX_LDFLAGS = toString (lib.optionals (!headless) [
      "-lfontconfig" "-lcups" "-lXinerama" "-lXrandr" "-lmagic"
    ] ++ lib.optionals (!headless && enableGtk) [
      "-lgtk-3" "-lgio-2.0"
    ]);

    # -j flag is explicitly rejected by the build system:
    #     Error: 'make -jN' is not supported, use 'make JOBS=N'
    # Note: it does not make build sequential. Build system
    # still runs in parallel.
    enableParallelBuilding = false;

    buildFlags = [ "images" ];

    installPhase = ''
      mkdir -p $out/lib

      mv build/*/images/jdk $out/lib/openjdk

      # Remove some broken manpages.
      rm -rf $out/lib/openjdk/man/ja*

      # Mirror some stuff in top-level.
      mkdir -p $out/share
      ln -s $out/lib/openjdk/include $out/include
      ln -s $out/lib/openjdk/man $out/share/man

      # IDEs use the provided src.zip to navigate the Java codebase (https://github.com/NixOS/nixpkgs/pull/95081)
      ln -s $out/lib/openjdk/lib/src.zip $out/lib/src.zip

      # jni.h expects jni_md.h to be in the header search path.
      ln -s $out/include/linux/*_md.h $out/include/

      # Remove crap from the installation.
      rm -rf $out/lib/openjdk/demo
      ${lib.optionalString headless ''
        rm $out/lib/openjdk/lib/{libjsound,libfontmanager}.so
      ''}

      ln -s $out/lib/openjdk/bin $out/bin
    '';

    preFixup = ''
      # Propagate the setJavaClassPath setup hook so that any package
      # that depends on the JDK has $CLASSPATH set up properly.
      mkdir -p $out/nix-support
      #TODO or printWords?  cf https://github.com/NixOS/nixpkgs/pull/27427#issuecomment-317293040
      echo -n "${setJavaClassPath}" > $out/nix-support/propagated-build-inputs

      # Set JAVA_HOME automatically.
      mkdir -p $out/nix-support
      cat <<EOF > $out/nix-support/setup-hook
      if [ -z "\''${JAVA_HOME-}" ]; then export JAVA_HOME=$out/lib/openjdk; fi
      EOF
    '';

    postFixup = ''
      # Build the set of output library directories to rpath against
      LIBDIRS=""
      for output in $(getAllOutputNames); do
        if [ "$output" = debug ]; then continue; fi
        LIBDIRS="$(find $(eval echo \$$output) -name \*.so\* -exec dirname {} \+ | sort -u | tr '\n' ':'):$LIBDIRS"
      done
      # Add the local library paths to remove dependencies on the bootstrap
      for output in $(getAllOutputNames); do
        if [ "$output" = debug ]; then continue; fi
        OUTPUTDIR=$(eval echo \$$output)
        BINLIBS=$(find $OUTPUTDIR/bin/ -type f; find $OUTPUTDIR -name \*.so\*)
        echo "$BINLIBS" | while read i; do
          patchelf --set-rpath "$LIBDIRS:$(patchelf --print-rpath "$i")" "$i" || true
          patchelf --shrink-rpath "$i" || true
        done
      done
    '';

    disallowedReferences = [ openjdk-bootstrap ];

    pos = builtins.unsafeGetAttrPos "feature" version;
    meta = import ./meta.nix lib version.feature;

    passthru = {
      architecture = "";
      home = "${openjdk}/lib/openjdk";
      inherit gtk3;
    };
  };
in openjdk
