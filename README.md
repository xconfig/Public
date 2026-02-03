🚀 Автоматическая установка на Debian-сервера 

Этот скрипт выполняет полную настройку сервера:
1. Обновление системы
2. Смена пароля root
3. Установка htop
4. Настройка SSH (смена порта, ключи и sshd_config)
5. Установка Docker и Docker Compose
6. Финальный шаг: установка 3X-UI

📜 Для запуска скрипта выполните команду:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/xconfig/Debian/main/debian-setup.sh)

