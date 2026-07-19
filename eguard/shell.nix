{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell.override { stdenv = pkgs.clangStdenv; } {
  buildInputs = with pkgs; [
    libbpf
    linuxHeaders
    cjson
  ];

  shellHook = ''
    export BPF_CLANG="${pkgs.llvmPackages.clang-unwrapped}/bin/clang"
    export CPATH="${pkgs.glibc.dev}/include:${pkgs.libbpf}/include:${pkgs.linuxHeaders}/include:${pkgs.cjson}/include"
    export LIBRARY_PATH="${pkgs.glibc}/lib:${pkgs.libbpf}/lib:${pkgs.linuxHeaders}/lib:${pkgs.cjson}/lib"
  '';
}
