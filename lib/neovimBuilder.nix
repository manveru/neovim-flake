{ pkgs, lib ? pkgs.lib, ...}:

{ config }:
let
  neovimPlugins = pkgs.neovimPlugins;

  vimOptions = lib.evalModules {
    modules = [
      { imports = [../modules]; }
      config 
    ];

    specialArgs = {
      inherit pkgs; 
    };
  };

  vim = vimOptions.config.vim;

  packdir = pkgs.symlinkJoin {
    name = "vimpackdir";
    paths = (builtins.attrValues neovimPlugins);
    postBuild = ''
	    mkdir $out/pack/MyPacks/opt -p
	    mv $out/share/vim-plugins $out/pack/MyPacks/start
    '';
  };

  vimcfg = pkgs.writeTextFile {
    name = "init.vim";
    text = ''
      " Configuration generated by NIX
      set nocompatible

      set packpath^=${packdir}
      set runtimepath^=${packdir}

      ${vim.configRC}
    '';
  };

  nvimWrapper = pkgs.writeScriptBin "nvim" ''
    !# ${pkgs.bash}/bin/bash
    exec -a "$0" ${pkgs.neovim-nightly}/bin/nvim -u ${vimcfg} $@
  '';

in pkgs.symlinkJoin {
  name = "nvim-master";
  paths = [ nvimWrapper ];

  postBuild = ''
    ${if vim.viAlias then ''
      ln -s $out/bin/nvim $out/bin/vi
    '' else ""}
    ${if vim.vimAlias then ''
      ln -s $out/bin/nvim $out/bin/vim
    '' else ""}
  '';
}
