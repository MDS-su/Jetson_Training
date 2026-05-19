#!/bin/bash

# ==========================================
# JetPack 6 & Additional Packages Setup Script
# ==========================================

# --- Color / style helpers ---
BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

section() {
    echo ""
    echo -e "${CYAN}${BOLD}${LINE}${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}${LINE}${RESET}"
    echo ""
}

ok()   { echo -e "  ${GREEN}${BOLD}[  DONE ✓]${RESET}  $1"; }
info() { echo -e "  ${YELLOW}${BOLD}[RUNNING ]${RESET}  $1"; }

# 1. Ask for the sudo password upfront and keep the session alive during the script execution.
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Disable interactive prompts during package installations.
export DEBIAN_FRONTEND=noninteractive

# 3. Prevent the script from exiting if an error occurs, moving on to the next step instead.
set +e # Disable "set -e" to ignore errors and continue.

section "1. JetPack 6.2.1 installation"
info "Installing JetPack..."

sudo apt update
sudo apt install nvidia-jetpack -y
if ! grep -q "export PATH=/usr/local/cuda/bin:\$PATH" "$HOME/.bashrc"; then
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> "$HOME/.bashrc"
fi
if ! grep -q "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH" "$HOME/.bashrc"; then
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> "$HOME/.bashrc"
fi

# Apply to current shell immediately
export PATH=/usr/local/cuda/bin:${PATH:-}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}
nvcc -V
ok "JetPack installed"

section "2. CUDA Utilities"
info "Building CUDA Samples..."
mkdir -p ~/workspace && cd ~/workspace
sudo apt install cmake -y
if [ ! -d "cuda-samples" ]; then
    git clone https://github.com/NVIDIA/cuda-samples.git
fi
cd cuda-samples/cpp/1_Utilities/deviceQuery
mkdir -p build && cd build
cmake ..
make
./deviceQuery
cd ~
ok "CUDA Utilities done"

section "3. Samba"
info "Installing Samba..."
sudo apt install samba -y
ok "Samba installed"

section "4. SSH"
info "Installing SSH..."
sudo apt install ssh -y
ok "SSH installed"

section "5. Chromium"
info "Installing Chromium..."

sudo apt update
snap download snapd --revision=24724
sudo snap ack snapd_24724.assert
sudo snap install snapd_24724.snap
sudo snap refresh --hold snapd
sudo apt install chromium-browser -y
rm snapd_24724.*
ok "Chromium installed"

section "6. Jetson GPIO"
info "Jetson GPIO is pre-installed. Skipping."
ok "Jetson GPIO verified"

section "7. OpenCV Sample Code"
info "Downloading OpenCV sample code..."

mkdir -p ~/workspace && cd ~/workspace
wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.4/sources/public_sources.tbz2
tar xjf public_sources.tbz2 && rm public_sources.tbz2
cp Linux_for_Tegra/source/opencv_gst_samples_src.tbz2 ./
sudo rm -r Linux_for_Tegra
tar xjf opencv_gst_samples_src.tbz2
rm opencv_gst_samples_src.tbz2
cd ~
ok "OpenCV sample code ready"

section "8. Ultralytics"
info "Installing Ultralytics and dependencies..."
cd ~
sudo apt install libgstrtspserver-1.0-0 python3-pip -y
pip3 install psutil tqdm openvino
pip3 install ultralytics
pip3 install onnxscript onnxslim
pip3 install onnx cmake py-cpuinfo
cd ~
ok "Ultralytics installed"

section "9. PyTorch with CUDA & Torchvision"
info "Installing PyTorch / Torchvision..."
TORCH_WHEEL_URL="https://pypi.jetson-ai-lab.io/jp6/cu126/+f/37d/7e156cfb4a646/torch-2.10.0-cp310-cp310-linux_aarch64.whl#sha256=37d7e156cfb4a646c4d7347597727db1529d184108f703324dfff1842cec094e"
VISION_WHEEL_URL="https://pypi.jetson-ai-lab.io/jp6/cu126/+f/1b6/357c5532db61e/torchvision-0.25.0-cp310-cp310-linux_aarch64.whl#sha256=1b6357c5532db61e9bfe7ad69f73ba73e8214010de021da703d360d2cc16c3d7"

if ! python3 -m pip --version >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y python3-pip
    python3 -m pip install -U pip
fi

# Remove existing packages
python3 -m pip uninstall -y torch torchvision >/dev/null 2>&1 || true

python3 -m pip install "${TORCH_WHEEL_URL}"
python3 -m pip install "${VISION_WHEEL_URL}"

# Install cuDSS
mkdir -p ~/workspace && cd ~/workspace
wget https://developer.download.nvidia.com/compute/cudss/0.6.0/local_installers/cudss-local-tegra-repo-ubuntu2204-0.6.0_0.6.0-1_arm64.deb
sudo dpkg -i cudss-local-tegra-repo-ubuntu2204-0.6.0_0.6.0-1_arm64.deb
sudo cp /var/cudss-local-tegra-repo-ubuntu2204-0.6.0/cudss-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cudss
sudo rm cudss-local-tegra-repo-ubuntu2204-0.6.0_0.6.0-1_arm64.deb

# Verification
echo "PyTorch Verification:"
info "Verifying PyTorch installation..."
python3 - <<'EOF'
import torch, torchvision
print("  torch       :", torch.__version__)
print("  torchvision :", torchvision.__version__)
print("  CUDA available :", torch.cuda.is_available())
print("  CUDA build ver :", torch.version.cuda)
EOF

sudo apt install vlc -y
ok "PyTorch / Torchvision installed"

section "10. DeepStream"
info "Installing DeepStream..."

DEEPSTREAM_PKG="deepstream-7.1"

# 0. Update GLib to 2.76.6 (Required)
sudo apt update
sudo apt install -y git meson ninja-build build-essential pkg-config libffi-dev libpcre2-dev zlib1g-dev libmount-dev libselinux1-dev gettext python3-pip

WORKDIR="/tmp/glib_build"
sudo rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

git clone https://github.com/GNOME/glib.git
cd glib
git checkout 2.76.6

meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
sudo ldconfig

# 1. Install base dependency packages
sudo apt update
sudo apt install -y libssl3 libssl-dev libgstreamer1.0-0 gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav libgstreamer-plugins-base1.0-dev libgstrtspserver-1.0-0 libjansson4 libyaml-cpp-dev

# 2. Install DeepStream SDK
NV_TEGRA_INFO=$(cat /etc/nv_tegra_release 2>/dev/null || echo "")
if [[ -n "$NV_TEGRA_INFO" ]]; then
    L4T_RELEASE=$(echo "$NV_TEGRA_INFO" | sed -n 's/.*R\([0-9]\+\).*/\1/p' | head -n 1)
    L4T_REVISION=$(echo "$NV_TEGRA_INFO" | sed -n 's/.*REVISION: \([0-9]\+\.[0-9]\+\).*/\1/p' | head -n 1)

    if [[ "$L4T_RELEASE" == "36" && "$L4T_REVISION" == "5.0" ]]; then
        sudo apt update
        sudo apt install -y curl
        mkdir -p ~/workspace && cd ~/workspace
        DEB_FILE="deepstream-7.1_7.1.0-1_arm64.deb"
        DEB_URL="https://api.ngc.nvidia.com/v2/resources/org/nvidia/deepstream/7.1/files?redirect=true&path=deepstream-7.1_7.1.0-1_arm64.deb"
        if [[ ! -f "$DEB_FILE" ]]; then
            curl -L "$DEB_URL" -o "$DEB_FILE"
        fi
        sudo apt-get install -y ./"$DEB_FILE"
    elif [[ "$L4T_RELEASE" == "36" && "$L4T_REVISION" == 4.* ]]; then
        sudo apt update
        if apt-cache show "${DEEPSTREAM_PKG}" >/dev/null 2>&1; then
            sudo apt-get install -y "${DEEPSTREAM_PKG}"
        else
            echo "[ERROR] DeepStream apt package not found."
        fi
    fi
fi
ok "DeepStream installed"

section "11. DeepStream-YOLO"
info "Installing DeepStream-YOLO and ONNX Runtime..."
cd ~
sudo apt update
sudo apt install libgstrtspserver-1.0-0 -y
pip3 install psutil tqdm openvino
pip3 install onnx cmake py-cpuinfo
wget https://nvidia.box.com/shared/static/6l0u97rj80ifwkk8rqbzj1try89fk26z.whl -O onnxruntime_gpu-1.19.0-cp310-cp310-linux_aarch64.whl
pip3 install onnxruntime_gpu-1.19.0-cp310-cp310-linux_aarch64.whl
rm onnxruntime_gpu-1.19.0-cp310-cp310-linux_aarch64.whl

if [ ! -d "DeepStream-Yolo" ]; then
    git clone https://github.com/marcoslucianops/DeepStream-Yolo.git
fi
cd ~
ok "DeepStream-YOLO installed"

section "12. UART"
info "Installing UART packages..."
cd ~
git clone https://github.com/JetsonHacksNano/UARTDemo
sudo apt-get install python3-serial -y
pip3 install pyserial
sudo apt install minicom -y
ok "UART installed"

echo ""
echo -e "${GREEN}${BOLD}${LINE}${RESET}"
echo -e "${GREEN}${BOLD}  All installations completed successfully!${RESET}"
echo -e "${GREEN}${BOLD}  Rebooting in 3 seconds...${RESET}"
echo -e "${GREEN}${BOLD}${LINE}${RESET}"
echo ""


sleep 3
sudo reboot