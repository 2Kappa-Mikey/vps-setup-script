#!/bin/bash

# 1. Обновление системы
echo "Обновление системы..."
apt update && apt upgrade -y

# 2. Настройка SSH - добавление SSH-ключа и отключение входа по паролю
echo "Настройка подключения по SSH ключу..."

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
mkdir -p $USER_HOME/.ssh
chmod 700 $USER_HOME/.ssh

# Запрос SSH-ключа у пользователя
echo "Введите ваш публичный SSH-ключ:"
read SSH_KEY < /dev/tty

# Проверка на пустой ввод
if [ -z "$SSH_KEY" ]; then
    echo "Ошибка: Вы не ввели SSH-ключ. Пожалуйста, не игнорируйте ввод ключа ибо потом вход будет невозможен."
    exit 1
fi

# Проверка, есть ли уже этот ключ в authorized_keys
if ! grep -q "$SSH_KEY" "$USER_HOME/.ssh/authorized_keys"; then
    # Если ключ не найден, добавляем его
    echo "$SSH_KEY" >> "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R $(whoami):$(whoami) "$USER_HOME/.ssh"
    echo "Новый SSH-ключ успешно добавлен."
else
    echo "Этот SSH ключ уже добавлен ранее."
fi

echo "Отключение паролей и разрешение ключевой авторизации только если ещё не настроено"
# Отключение паролей и разрешение ключевой авторизации только если ещё не настроено
if grep -q "^#PasswordAuthentication yes" /etc/ssh/sshd_config; then
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "PasswordAuthentication отключен."
fi
if grep -q "^#PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    echo "PubkeyAuthentication разрешен."
fi
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    echo "Root-логин по паролю запрещен."
fi

systemctl reload sshd

# 3. Установка и настройка firewall UFW
echo "Установка и настройка ufw..."
apt install ufw -y
ufw status | grep -q "inactive" && {
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw enable
    echo "UFW активирован и настроен."
}

# 4. Отключение двухстороннего пинга (ICMP) в UFW
echo "Отключение двухстороннего пинга в ufw..."
if ! grep -q "icmp" /etc/ufw/before.rules; then
    sed -i '/^# End required lines/i \
    # Отключение ICMP echo request и reply \
    -A ufw-before-input -p icmp --icmp-type echo-request -j DROP \
    -A ufw-before-output -p icmp --icmp-type echo-reply -j DROP' /etc/ufw/before.rules
    ufw reload
    echo "ICMP блокировка добавлена."
else
    echo "ICMP уже заблокирован."
fi

# 5. Установка и настройка fail2ban
echo "Установка fail2ban..."
apt install fail2ban -y

# Проверка существования конфигурации fail2ban
if [ ! -f /etc/fail2ban/jail.local ]; then
    cat <<EOT >> /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
maxretry = 3
findtime = 600
bantime = 86400
EOT
    systemctl restart fail2ban
    echo "Fail2Ban настроен для SSH."
else
    echo "Fail2Ban уже настроен."
fi

# 6. Включение TCP BBR
echo "Включение TCP BBR..."
if ! sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_congestion_control=bbr

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    echo "TCP BBR включен."
else
    echo "TCP BBR уже включен."
fi

# 7. Установка nano
echo "Установка nano"
apt install nano

# 8. Очистка 
echo "Очистка напоследок"
apt autoclean -y && apt clean -y && apt autoremove -y

echo "Настройка завершена!"
