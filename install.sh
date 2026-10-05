#!/usr/bin/env bash
set -euo pipefail
if [ "$(id -u)" -eq 0 ]; then
    echo 'Execute como usuário normal. O instalador solicitará sudo apenas para pacotes e serviço.' >&2
    exit 1
fi
repo_url='https://github.com/poajefersonld-1983/DriveBridge-Desktop.git'
project_dir="${DRIVEBRIDGE_INSTALL_DIR:-$HOME/DriveBridge-Desktop}"
if command -v apt-get >/dev/null; then
    sudo apt-get update
    packages=(git python3 python3-venv)
    packages+=(python3-tk)
    sudo apt-get install -y "${packages[@]}"
elif command -v dnf >/dev/null; then
    sudo dnf install -y git python3 python3-tkinter
else
    echo 'Instale Git, Python 3.10+, venv e Tkinter (desktop) usando seu gerenciador de pacotes.' >&2
    command -v git >/dev/null
    command -v python3 >/dev/null
fi
if [ -d "$project_dir/.git" ]; then
    remote=$(git -C "$project_dir" remote get-url origin)
    if [ "$remote" != "$repo_url" ]; then
        echo 'A pasta de destino pertence a outro repositório. Defina DRIVEBRIDGE_INSTALL_DIR para uma pasta nova.' >&2
        exit 1
    fi
    if [ -n "$(git -C "$project_dir" status --porcelain)" ]; then
        echo 'Há alterações na pasta existente. Preserve suas mudanças antes de atualizar.' >&2
        exit 1
    fi
    git -C "$project_dir" pull --ff-only
elif [ -e "$project_dir" ]; then
    echo 'A pasta de destino já existe e não será sobrescrita. Defina DRIVEBRIDGE_INSTALL_DIR para uma pasta nova.' >&2
    exit 1
else
    git clone "$repo_url" "$project_dir"
fi
cd "$project_dir"
./tools/install-desktop.sh
printf '\nInstalação concluída. Nenhuma conta Google foi incluída: conecte a sua pelo aplicativo.\n'
