{
  stdenv,
  shellcheck,
  dash,
  # Программы
  coreutils-full,
  util-linux,
  gnugrep,
  gnused,
  # Переменные
  outpath ? "/var/www/resourcepacks/",
  resourcepack_namespace_path ? "/run/agenix/resourcepack_namespace",
}:
stdenv.mkDerivation {
  pname = "elysium-server-control-scripts";
  version = "1.0";

  src = ./.;

  dontUnpack = false;

  nativeBuildInputs = [shellcheck];
  buildInputs = [dash];

  buildPhase = ''
    mkdir -p build_stage/bin build_stage/internal

    cp update_resourcepack build_stage/bin/
    substituteInPlace build_stage/bin/update_resourcepack \
        --replace-fail "#!/bin/sh" "#!${dash}/bin/dash" \
        --replace-fail "sha1sum" "${coreutils-full}/bin/sha1sum" \
        --replace-fail "./publish_resourcepack" "$out/internal/publish_resourcepack" \
        --replace-fail "grep" "${gnugrep}/bin/grep" \
        --replace-fail "sed" "${gnused}/bin/sed"

    cp publish_resourcepack build_stage/internal/
    substituteInPlace build_stage/internal/publish_resourcepack \
        --replace-fail "#!/bin/sh" "#!${dash}/bin/dash" \
        --replace-fail "out/" "${outpath}" \
        --replace-fail "cat" "${coreutils-full}/bin/cat" \
        --replace-fail "resourcepack_namespace" "${resourcepack_namespace_path}" \
        --replace-fail "uuidgen" "${util-linux}/bin/uuidgen" \
        --replace-fail "cp" "${coreutils-full}/bin/cp"
  '';

  doCheck = true;
  checkPhase = ''
    shellcheck -s dash build_stage/bin/update_resourcepack build_stage/internal/publish_resourcepack
  '';

  installPhase = ''
    mkdir -p $out/bin $out/internal
    cp -r build_stage/bin/ $out/
    cp -r build_stage/internal/ $out/
  '';
}
