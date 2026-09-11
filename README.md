نصب واقعی سرور جدید

curl -fsSL https://raw.githubusercontent.com/taymaz1987/Ticket-Installer/main/install.sh | sudo bash

تست Installer بدون تغییر

curl -fsSL https://raw.githubusercontent.com/taymaz1987/Ticket-Installer/main/install.sh \
| bash -s -- --ref staging --self-test

نمایش Wizard بدون نصب

curl -fsSL https://raw.githubusercontent.com/taymaz1987/Ticket-Installer/main/install.sh \
| bash -s -- --ref staging --plan
