#!/bin/bash
set -euo pipefail

# ===== Functions =====

update_system() {
  echo "==== Updating system ===="
  sudo pacman -Syu
}

install_snapshots() {
  echo "==== Installing snapshot support ===="
  if ! pacman -Qi snapper-support &>/dev/null; then
    yay -S snapper-support btrfs-assistant
  else
    echo ">> Snapshot support already installed"
  fi

  if ! grep -q ".snapshots" /etc/updatedb.conf; then
    sudo sed -i 's/^PRUNENAMES.*/PRUNENAMES = ".git .hg .svn .snapshots"/' /etc/updatedb.conf
    echo ">> Updated /etc/updatedb.conf"
  else
    echo ">> .snapshots already excluded in updatedb"
  fi
}

setup_switcheroo() {
  echo "==== Setting up switcheroo-control ===="
  if ! pacman -Qi switcheroo-control &>/dev/null; then
    sudo pacman -S switcheroo-control
  fi
  sudo systemctl enable --now switcheroo-control || true
}

setup_auto_cpufreq() {
  echo "==== Installing auto-cpufreq ===="
  if ! yay -Qi auto-cpufreq &>/dev/null; then
    yay -S auto-cpufreq
  fi
  sudo systemctl enable --now auto-cpufreq || true
}

setup_cachyos() {
  echo "==== Adding CachyOS repository ===="
  if ! pacman -Sl | grep -q cachyos; then
    curl -LO https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz
    cd cachyos-repo
    sudo ./cachyos-repo.sh
    cd ..
    rm -rf cachyos-repo cachyos-repo.tar.xz
  else
    echo ">> CachyOS repo already added"
  fi

  echo "==== Installing CachyOS Kernel Manager ===="
  if ! yay -Qi cachyos-kernel-manager &>/dev/null; then
    yay -S cachyos-kernel-manager
  fi
  echo ">>> Run 'cachyos-kernel-manager' manually to pick your kernel."
}

setup_grub() {
  echo "==== Configuring GRUB ===="
  sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
  sudo sed -i 's/^#GRUB_SAVEDEFAULT.*/GRUB_SAVEDEFAULT=true/' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg
}

setup_zsh() {
  echo "==== Installing Zsh ===="
  if ! pacman -Qi zsh &>/dev/null; then
    sudo pacman -S zsh
  fi
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)"
  fi
}

install_flatpak_apps() {
  echo "==== Installing Flatpak and apps ===="
  if ! pacman -Qi flatpak &>/dev/null; then
    sudo pacman -S flatpak
  fi

  apps=(
    com.discordapp.Discord
    org.gimp.GIMP
    com.spotify.Client
    io.github.shiftey.Desktop
    com.github.tchx84.Flatseal
    org.onlyoffice.desktopeditors
  )
  for app in "${apps[@]}"; do
    if ! flatpak list | grep -q "$app"; then
      flatpak install -y flathub "$app"
    else
      echo ">> $app already installed"
    fi
  done
  flatpak update -y
}

install_extra_apps() {
  echo "==== Installing additional packages ===="
  pkgs=(steam vlc obs-studio kdenlive tree fastfetch audacity kolourpaint)
  for pkg in "${pkgs[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
      sudo pacman -S "$pkg"
    fi
  done

  yay -S --needed code ttf-ms-win11-auto
}

setup_cpp_dev() {
  echo "==== Setting up C++ development environment ===="

  base_cpp=(base-devel cmake ninja gdb lldb clang ccache pkg-config git)
  cpp_libs=(glew sdl3 glfw-x11 glm vulkan-headers vulkan-tools)

  for pkg in "${base_cpp[@]}" "${cpp_libs[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
      sudo pacman -S "$pkg"
    fi
  done
}

# ===== Menu =====

sections=(
  "Update System"
  "Install Snapshot Support"
  "Setup Switcheroo"
  "Setup Auto CPUFreq"
  "Setup CachyOS Repo + Kernel Manager"
  "Configure GRUB"
  "Setup Zsh"
  "Install Flatpak + Apps"
  "Install Extra Apps"
  "Setup C++ Development"
  "Run All"
)

echo "==== Select section to run ===="
select choice in "${sections[@]}"; do
  case $choice in
    "Update System") update_system ;;
    "Install Snapshot Support") install_snapshots ;;
    "Setup Switcheroo") setup_switcheroo ;;
    "Setup Auto CPUFreq") setup_auto_cpufreq ;;
    "Setup CachyOS Repo + Kernel Manager") setup_cachyos ;;
    "Configure GRUB") setup_grub ;;
    "Setup Zsh") setup_zsh ;;
    "Install Flatpak + Apps") install_flatpak_apps ;;
    "Install Extra Apps") install_extra_apps ;;
    "Setup C++ Development") setup_cpp_dev ;;
    "Run All")
      update_system
      install_snapshots
      setup_switcheroo
      setup_auto_cpufreq
      setup_cachyos
      setup_grub
      setup_zsh
      install_flatpak_apps
      install_extra_apps
      setup_cpp_dev
      ;;
    *) echo "Invalid choice";;
  esac
  break
done

echo "==== Setup complete! ===="
