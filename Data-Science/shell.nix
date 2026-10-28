{ pkgs ? import <nixpkgs> {} }:

 pkgs.mkShellNoCC {
    packages = [
      pkgs.rakudo
      pkgs.zef
    ];

    shellHook = ''
      export PATH=$HOME/.raku/bin:$PATH
      zef install Markdown::Grammar File::Find "Text::CSV:ver<0.022>:auth<zef:Tux>"
    '';    
}
