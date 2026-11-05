FROM ubuntu:24.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server sudo python3 python3-apt \
    && useradd --create-home --shell /bin/bash ansible \
    && echo 'ansible:ansible' | chpasswd \
    && usermod -aG sudo ansible \
    && echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible \
    && chmod 0440 /etc/sudoers.d/ansible \
    && visudo -cf /etc/sudoers.d/ansible \
    && printf 'PasswordAuthentication yes\nPermitRootLogin no\n' > /etc/ssh/sshd_config.d/00-practica.conf \
    && mkdir -p /run/sshd \
    && rm -f /etc/ssh/ssh_host_* \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 22

# Cada contenedor genera sus propias claves SSH, no comparte las de la imagen.
CMD ["/bin/sh", "-c", "ssh-keygen -A && exec /usr/sbin/sshd -D -e"]
