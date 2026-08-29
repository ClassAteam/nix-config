# AdGuard VPN CLI is not in nixpkgs, so we package the vendor release here.
# The upstream binary is fully statically linked, so no patchelf/autoPatchelf
# is needed - it runs as-is on NixOS.
#
# To bump: change version, then get the new hash with
#   nix-prefetch-url --type sha256 <url>   (then nix hash to-sri --type sha256 <hash>)
{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "adguardvpn-cli";
  version = "1.7.12";

  src = fetchurl {
    url = "https://github.com/AdguardTeam/AdGuardVPNCLI/releases/download/v${finalAttrs.version}-release/adguardvpn-cli-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-pwaTPIfsiO7IV4zOltK5HDheCDz3OKgG5ps7zYd/uIw=";
  };

  nativeBuildInputs = [ installShellFiles ];

  dontFixup = true;   # prebuilt static binary, already stripped

  installPhase = ''
    runHook preInstall
    install -Dm755 adguardvpn-cli $out/bin/adguardvpn-cli
    installShellCompletion --bash --name adguardvpn-cli bash-completion.sh
    runHook postInstall
  '';

  meta = {
    description = "AdGuard VPN command-line client";
    homepage = "https://github.com/AdguardTeam/AdGuardVPNCLI";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "adguardvpn-cli";
  };
})
