
#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora-inspired GNOME setup for Kali Linux
# Run from a GNOME desktop session.

if [[ $EUID -eq 0 ]]; then
    echo "Run this script as your normal user, not with sudo."
    exit 1
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]] &&
   [[ "${DESKTOP_SESSION:-}" != *gnome* ]]; then
    echo "Warning: GNOME was not detected. Install/use a GNOME session first."
    read -r -p "Continue anyway? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 1
fi

echo "[1/5] Updating package lists..."
sudo apt update

echo "[2/5] Installing GNOME customization tools..."
packages=(
    gnome-tweaks
    gnome-shell-extension-manager
    gnome-shell-extensions
    gnome-shell-extension-dashtodock
    gnome-shell-extension-appindicator
    papirus-icon-theme
    fonts-cantarell
)

available=()
for package in "${packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
        available+=("$package")
    else
        echo "Skipping unavailable package: $package"
    fi
done

sudo apt install -y "${available[@]}"

echo "[3/5] Applying GNOME appearance..."
gsettings set org.gnome.desktop.interface enable-animations true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

echo "[4/5] Enabling available extensions..."
enable_extension() {
    local uuid="$1"
    if gnome-extensions list 2>/dev/null | grep -Fxq "$uuid"; then
        gnome-extensions enable "$uuid" 2>/dev/null || true
        echo "Enabled: $uuid"
    fi
}

enable_extension "dash-to-dock@micxgx.gmail.com"
enable_extension "appindicatorsupport@rgcjonas.gmail.com"
enable_extension "user-theme@gnome-shell-extensions.gcampax.github.com"

# Configure the dock only if its settings schema exists.
if gsettings list-schemas | grep -Fxq \
    'org.gnome.shell.extensions.dash-to-dock'; then

    schema='org.gnome.shell.extensions.dash-to-dock'

    set_dock_setting() {
        local key="$1"
        local value="$2"

        if gsettings list-keys "$schema" | grep -Fxq "$key"; then
            gsettings set "$schema" "$key" "$value" || true
        fi
    }

    set_dock_setting dock-position "'BOTTOM'"
    set_dock_setting extend-height "false"
    set_dock_setting dock-fixed "true"
    set_dock_setting autohide "true"
    set_dock_setting intellihide "true"
    set_dock_setting dash-max-icon-size "40"
    set_dock_setting show-trash "false"
    set_dock_setting show-mounts "false"
fi

echo "[5/5] Finalizing..."
echo
echo "Setup complete!"
echo "Log out and log back in to reload GNOME extensions."
echo "Use GNOME Tweaks and Extension Manager for further customization."
