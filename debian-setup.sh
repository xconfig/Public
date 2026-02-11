#!/bin/bash
# server-prep.sh - Моя настройка Debian сервера
# Запуск: bash <(curl -Ls https://raw.githubusercontent.com/xconfig/Debian/main/debian-setup.sh)
# Автор: Al1en

set -e  # Останавливаться при ошибке

echo "🚀 Настройка Debian сервера начата: $(date)"

# 1. Обновление системы
echo "📦 Обновление пакетов..."
apt update && apt upgrade -y
echo "✅ Система обновлена"

# 2. Интерактивная смена пароля root
echo "🔐 Смена пароля root..."
passwd
echo "✅ Пароль root изменен"

# 3. Установка btop
echo "📊 Установка btop..."
apt install btop -y
echo "✅ btop установлен"

# 4. Установка Настраиваем время и часовой пояс
echo "   🕒 Настраиваем время и часовой пояс (MSK)..."
# Часовой пояс Москва
timedatectl set-timezone Europe/Moscow
# Включаем NTP синхронизацию
timedatectl set-ntp true
systemctl restart systemd-timesyncd 2>/dev/null || true
# Русская локаль ТОЛЬКО для времени (24h формат), остальное английский
sed -i 's/^# *ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen ru_RU.UTF-8 en_US.UTF-8
# КЛЮЧЕВОЕ: только LC_TIME на русский (24h), остальное en_US
update-locale LANG=en_US.UTF-8 \
              LC_TIME=ru_RU.UTF-8 \
              LC_CTYPE=en_US.UTF-8 \
              LC_COLLATE=en_US.UTF-8 \
              LC_MESSAGES=en_US.UTF-8
echo "   ✅ Установлен 24-часовой формат"

# 5. Настройка SSH (сложная последовательность)
echo "🔐 Настройка SSH: смена порта + ключи..."

# 5.1. Меняем порт SSH (спросить у пользователя)
read -rp "Введите новый порт SSH : " SSH_PORT
SSH_PORT=${SSH_PORT}
# Меняем строку Port 22 (закомментированную и активную) на выбранный порт
sed -i "s/^#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i "s/^Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
echo "   ✅ Порт SSH изменен на ${SSH_PORT}"

# 5.2. Генерируем SSH ключ ed25519 (МОИ имена файлов)
ssh-keygen -t ed25519 -f ~/.ssh/server_key -a 100 -C "server $(hostname)"
echo "   ✅ SSH ключ сгенерирован: ~/.ssh/server_key"

# 5.3. Создаем директорию .ssh и authorized_keys
mkdir -p ~/.ssh
cat ~/.ssh/server_key.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
rm -f ~/.ssh/server_key.pub  # Удаляем публичный ключ
echo "   ✅ Публичный ключ перенесен в authorized_keys"

# 5.4. Показываем приватный ключ для сохранения
echo "   📤 ПРИВАТНЫЙ КЛЮЧ (скопируйте и сохраните в надежном месте):"
cat ~/.ssh/server_key
echo ""
echo "   ⚠️  СОХРАНИТЕ ЭТОТ КЛЮЧ В НАДЕЖНОМ МЕСТЕ!"

# 5.5. Ждем подтверждения сохранения ключа и УДАЛЯЕМ приватный ключ
read -p "Сохранили ключ в надежном месте? Нажмите Enter для удаления ключа..."
rm -f ~/.ssh/server_key
echo "   ✅ Приватный ключ удален с сервера"
echo "   ✅ Теперь ключ ТОЛЬКО у вас в надежном месте"

# 5.6. Настройка sshd_config: только ключи, без паролей
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^#*UsePAM.*/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
echo "   ✅ sshd_config: только ключевая авторизация"

# 5.7. Перезапускаем SSH
systemctl restart ssh
echo "✅ SSH настроен: порт 21234, только ключи"
echo "⚠️  Подключайтесь: ssh -p 21234 -i server_key root@IP"

# 6. Предложение установить Docker
echo ""
echo "🌐 === УСТАНОВИТЬ Docker? ==="
read -p "Установить Docker? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Запускаем установку Docker..."

    # 5. Установка Docker + Docker Compose (официальный репозиторий)
    echo "🐳 Установка Docker и Docker Compose..."

    # 5.1. Установка зависимостей
    apt install -y ca-certificates curl gnupg lsb-release
    echo "   ✅ Зависимости установлены"

    # 5.2. Добавляем GPG ключ Docker ✅ ИСПРАВЛЕНО
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "   ✅ GPG ключ Docker добавлен"

    # 5.3. Добавляем репозиторий Docker ✅ ИСПРАВЛЕНО
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo "   ✅ Репозиторий Docker добавлен"

    # 5.4. Обновляем пакеты и устанавливаем Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "   ✅ Docker установлен"

    # 5.5. Запускаем и включаем Docker в автозагрузку
    systemctl start docker
    systemctl enable docker
    echo "   ✅ Docker запущен и добавлен в автозагрузку"

    # 5.6. Проверяем установку Docker
    docker --version
    docker compose version
    echo "✅ Docker и Docker Compose установлены!"
fi  # ← ✅ ЗАКРЫВАЕМ Docker if

# 7. Финальное предложение 3X-UI
echo ""
echo "🌐 === УСТАНОВИТЬ 3X-UI ПАНЕЛЬ? ==="
echo "Запустить установку 3X-UI панели управления?"
read -p "Установить 3X-UI? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Запускаем установку 3X-UI..."
    echo "📢 После завершения 3X-UI перезагрузите сервер: reboot"
    echo ""
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    # СКРИПТ ЗАВЕРШАЕТСЯ ЗДЕСЬ - управление в 3X-UI
else
    echo ""
    echo "❌ Установка 3X-UI пропущена"
    echo ""
    echo "🎉 Базовая настройка сервера завершена!"
    echo "🔄 Не плохо бы перезагрузить сервер:"
    echo "   reboot"
    echo ""
fi
