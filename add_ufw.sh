# Отключение двухстороннего пинга в ufw
echo "Отключение двухстороннего пинга в ufw..."
if grep -q "^-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT" /etc/ufw/before.rules; then
    sed -i 's/^-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/' /etc/ufw/before.rules
	ufw reload
    echo "ICMP отключён."
fi
