{ pkgs ? import <nixpkgs> {} }:

 pkgs.mkShellNoCC {
    packages = [
      pkgs.rakudo
      pkgs.zef
      pkgs.wget
      (pkgs.python3.withPackages (ps: with ps; [
        jupyterlab
        pandas
        numpy
        matplotlib
        seaborn
        requests
        ollama
        itables
        jupyterlab-lsp
        jupyterlab-git
        jupyterlab-widgets
        jedi-language-server
      ]))
    ];

    # Set zef environment variables
    ZEF_FETCH_DEGREE = 4;
    ZEF_TEST_DEGREE = 4;

    shellHook = ''
      export PATH=$HOME/.raku/bin:$PATH
      
      echo "..."
      echo INSTALL RAKU MODULES:
      echo "nohup nice zef install Markdown::Grammar File::Find 'Text::CSV:ver<0.022>:auth<zef:Tux>' &"
      echo "..."

      echo "..."
      echo START JUPYTER:
      echo "nohup nice jupyter-lab --notebook-dir=Lectures Lectures/biber-results-analytics.ipynb &"
      echo "..."

      echo "..."
      echo Reload shell.nix after change:
      echo "direnv reload"
      echo "..." 

      echo "..."
      echo Kill all Jupyter processes
      echo "pkill -f 'jupyter-(notebook|lab)'"
      echo "..." 
    '';
}
