#!/bin/bash

# 1. Обновление системы
echo "Обновление системы..."
apt update && apt upgrade -y

# 2. Настройка SSH - добавление SSH-ключа и отключение входа по паролю
echo "Настройка подключения по SSH ключу..."

# Определяем домашнюю директорию текущего пользователя (не root)
USER_HOME=$(eval echo ~$SUDO_USER)
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"

# Запрос SSH-ключа у пользователя
echo "Введите ваш публичный SSH-ключ:"
read SSH_KEY < /dev/tty

# Проверка на пустой ввод
if [ -z "$SSH_KEY" ]; then
    echo "Ошибка: Вы не ввели SSH-ключ. Пожалуйста, не игнорируйте ввод ключа ибо потом вход будет невозможен."
    exit 1
fi

# Проверка, есть ли ключ уже в authorized_keys
if ! grep -q "$SSH_KEY" "$USER_HOME/.ssh/authorized_keys"; then
    # Если ключ не найден, добавляем его
    echo "$SSH_KEY" >> "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.ssh"
    echo "Новый SSH-ключ успешно добавлен."
else
    echo "Этот SSH ключ уже добавлен ранее."
fi
