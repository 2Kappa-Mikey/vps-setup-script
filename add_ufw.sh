echo "Отключение двухстороннего пинга в ufw..."

# Проверяем, есть ли уже правила для блокировки ICMP
if ! grep -q "icmp --icmp-type echo-request" /etc/ufw/before.rules; then
    echo "Добавляем правила блокировки ICMP..."

    # Добавляем правила в before.rules
    cat <<EOT >> /etc/ufw/before.rules
# Отключение ICMP echo request и reply
-A ufw-before-input -p icmp --icmp-type echo-request -j DROP
EOT

    # Перезагружаем UFW для применения изменений
    ufw reload

    if [ $? -eq 0 ]; then
        echo "ICMP блокировка добавлена и UFW перезагружен."
    else
        echo "Ошибка при перезагрузке UFW."
    fi
else
    echo "ICMP уже заблокирован."
fi
