# Repo-local Haskell package overrides, applied on top of ghc96 in devenv.nix.
#
# `pkgs` is passed in so overrides can reach the `pkgs.haskell.lib` helpers
# (dontCheck, doJailbreak, callHackageDirect, …).
#
# statics-common is the shared package from master-builder; it is built straight
# from the pinned submodule rather than from Hackage.
{ pkgs }:
hself: hsuper: {
  statics-common =
    hself.callCabal2nix "statics-common"
      ./vendor/master-builder/packages-hs/statics-common
      { };
}
