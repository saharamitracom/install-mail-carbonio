#!/bin/bash

# ==========================================================================
# CARBONIO CE AUTO-INSTALLER FOR UBUNTU 22.04 & 24.04 
# ==========================================================================

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Memulai Persiapan Instalasi Carbonio CE ===${NC}"

# 1. Cek User Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script ini harus dijalankan dengan sudo / root!${NC}"
   exit 1
fi

# 2. Input FQDN dari User
read -p "Masukkan FQDN (contoh: mail.domainanda.com): " MY_HOSTNAME
if [ -z "$MY_HOSTNAME" ]; then
    echo -e "${RED}Hostname tidak boleh kosong!${NC}"
    exit 1
fi

# 3. Deteksi IP Address (Otomatis mengambil IP Utama)
MY_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}[INFO] Mendeteksi IP Server: $MY_IP${NC}"

# 4. Update Hostname di Sistem
echo -e "${GREEN}[1/6] Mengatur Hostname ke $MY_HOSTNAME...${NC}"
hostnamectl set-hostname "$MY_HOSTNAME"

# 5. Konfigurasi /etc/hosts (Sangat Penting untuk Carbonio)
echo -e "${GREEN}[2/6] Mengonfigurasi /etc/hosts...${NC}"
# Backup hosts lama
cp /etc/hosts /etc/hosts.bak
# Hapus baris yang mengandung hostname lama jika ada, lalu tambah yang baru
sed -i "/$MY_HOSTNAME/d" /etc/hosts
echo "$MY_IP $MY_HOSTNAME ${MY_HOSTNAME%%.*}" >> /etc/hosts

# 6. Tambahkan Repository Carbonio
echo -e "${GREEN}[3/5] Menambahkan Repository Zextras Carbonio...${NC}"
CODENAME=$(lsb_release -sc)
wget -O- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x5dc7680bc4378c471a7fa80f52fd40243e584a21" | gpg --dearmor | sudo tee /usr/share/keyrings/zextras.gpg > /dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/zextras.gpg] https://repo.zextras.io/release/ubuntu $CODENAME main" | tee /etc/apt/sources.list.d/zextras.list

apt update

# 7. Instalasi Paket Utama (Single Server)
echo -e "${GREEN}[4/5] Mengunduh dan Menginstall Paket Carbonio...${NC}"
echo -e "${GREEN}Proses ini akan memakan waktu lama tergantung koneksi internet.${NC}"

# Paket dasar untuk single-node installation
wget https://docs.zextras.com/carbonio-ce/html/_downloads/bed211d6fc1b9ca35f15be01eb9aa3fc/install_carbonio_ce_singleserver_ubuntu.sh
chmod +x install_carbonio_ce_singleserver_ubuntu.sh
sudo ./install_carbonio_ce_singleserver_ubuntu.sh

# 8. Selesai
echo -e "--------------------------------------------------------"
echo -e "${GREEN}INSTALASI SELESAI (TAHAP AWAL)${NC}"
echo -e "Langkah selanjutnya yang HARUS dilakukan:"
echo -e "1. Setup Password Admin: ${RED}sudo su - zextras -c \"carbonio prov sp zextras@domainanda.com PasswordKu123\"${NC}"
echo -e "2. Reboot Server: ${RED}sudo reboot${NC}"
echo -e "--------------------------------------------------------"
