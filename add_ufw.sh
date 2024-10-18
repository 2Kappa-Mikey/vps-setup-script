echo "Отключение двухстороннего пинга в ufw..."

# Проверяем наличие строки с "icmp" в before.rules
if ! grep -q "icmp" /etc/ufw/before.rules; then
    echo "Добавляем правила блокировки ICMP..."
    
    # Добавляем правила в /etc/ufw/before.rules с использованием многострочного ввода
    sed -i '/^# End required lines/i \
# Отключение ICMP echo request и reply \n\
-A ufw-before-input -p icmp --icmp-type echo-request -j DROP \n\
-A ufw-before-output -p icmp --icmp-type echo-reply -j DROP' /etc/ufw/before.rules

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
