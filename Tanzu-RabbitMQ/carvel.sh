#!/bin/bash

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

install() {
  set -euo pipefail

  dst_dir="${K14SIO_INSTALL_BIN_DIR:-/usr/local/bin}"

  if [ -x "$(command -v wget)" ]; then
    dl_bin="wget -nv -O- --no-check-certificate"
  else
    dl_bin="curl -s -L -k"
  fi

  shasum -v 1>/dev/null 2>&1 || (echo "Missing shasum binary" && exit 1)

  if [[ `uname` == Darwin ]]; then
    binary_type=darwin-amd64
    
    ytt_checksum=b188f6a6f0c44ef8d3cf07d5237dcfa79d04b8c2823d697b58de7236034fb03a
    imgpkg_checksum=f0c87c8caefb3d2a82e648779b36783403fe5c93930df2d5cbf4968713933392
    kbld_checksum=5fc8a491327294717611974c6ab3da2bda3f3809ef3147c1e8472ac62af3ee18
    kapp_checksum=44f66b7ed664e4537b2caa0453aa239f16e20c028b11fedc22f46f3cac3ba9fd
    kwt_checksum=555d50d5bed601c2e91f7444b3f44fdc424d721d7da72955725a97f3860e2517
    vendir_checksum=f3a738d1fe55803ad5faba495f662c48efa230976ccad7a159587dcf9b020f63
  else
    binary_type=linux-amd64
    
    ytt_checksum=7a472b8c62bfec5c12586bb39065beda42c6fe43cf24271275e4dbc0a04acb8b
    imgpkg_checksum=cfcfcb5afc5e3d28ce1f2f67971a4dcd18f514dadf8a63d70c864e49c9ddca7e
    kbld_checksum=de546ac46599e981c20ad74cd2deedf2b0f52458885d00b46b759eddb917351a
    kapp_checksum=9d2c0441729bebe49e5fb9a1a7b7088f0bee4092ba23e267339a9478948c5731
    kwt_checksum=92a1f18be6a8dca15b7537f4cc666713b556630c20c9246b335931a9379196a0
    vendir_checksum=b7bfd227aa2e6df602f8e79edf725bb0a944b68d207005f42f46f061c4ecd55a
  fi

  echo "Installing ${binary_type} binaries..."

  
  echo "Installing ytt..."
  $dl_bin github.com/vmware-tanzu/carvel-ytt/releases/download/v0.39.0/ytt-${binary_type} > /tmp/ytt
  echo "${ytt_checksum}  /tmp/ytt" | shasum -c -
  mv /tmp/ytt ${dst_dir}/ytt
  chmod +x ${dst_dir}/ytt
  echo "Installed ${dst_dir}/ytt v0.39.0"
  
  echo "Installing imgpkg..."
  $dl_bin github.com/vmware-tanzu/carvel-imgpkg/releases/download/v0.24.0/imgpkg-${binary_type} > /tmp/imgpkg
  echo "${imgpkg_checksum}  /tmp/imgpkg" | shasum -c -
  mv /tmp/imgpkg ${dst_dir}/imgpkg
  chmod +x ${dst_dir}/imgpkg
  echo "Installed ${dst_dir}/imgpkg v0.24.0"
  
  echo "Installing kbld..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kbld/releases/download/v0.32.0/kbld-${binary_type} > /tmp/kbld
  echo "${kbld_checksum}  /tmp/kbld" | shasum -c -
  mv /tmp/kbld ${dst_dir}/kbld
  chmod +x ${dst_dir}/kbld
  echo "Installed ${dst_dir}/kbld v0.32.0"
  
  echo "Installing kapp..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.45.0/kapp-${binary_type} > /tmp/kapp
  echo "${kapp_checksum}  /tmp/kapp" | shasum -c -
  mv /tmp/kapp ${dst_dir}/kapp
  chmod +x ${dst_dir}/kapp
  echo "Installed ${dst_dir}/kapp v0.45.0"
  
  echo "Installing kwt..."
  $dl_bin https://github.com/vmware-tanzu/carvel-kwt/releases/download/v0.0.6/kwt-${binary_type} > /tmp/kwt
  echo "${kwt_checksum}  /tmp/kwt" | shasum -c -
  mv /tmp/kwt ${dst_dir}/kwt
  chmod +x ${dst_dir}/kwt
  echo "Installed ${dst_dir}/kwt v0.0.6"
  
  echo "Installing vendir..."
  $dl_bin https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.24.0/vendir-${binary_type} > /tmp/vendir
  echo "${vendir_checksum}  /tmp/vendir" | shasum -c -
  mv /tmp/vendir ${dst_dir}/vendir
  chmod +x ${dst_dir}/vendir
  echo "Installed ${dst_dir}/vendir v0.24.0"
  
}

install
