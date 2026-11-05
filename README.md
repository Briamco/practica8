# Practica 8: automatizacion con Ansible y Docker

Cinco contenedores Ubuntu 24.04 simulan servidores administrados por SSH.
Ansible actualiza la cache de APT, crea el usuario `itla`, la carpeta
`/home/itla/app` y su archivo `hola.txt`, e instala `cowsay` y `htop`.

> Solo para una practica local. La clave `ansible`, sudo sin contrasena y la
> verificacion de claves SSH desactivada son inseguros para produccion.
> Los contenedores comparten el kernel del anfitrion: no son maquinas virtuales.

## 1. Preparar Windows y WSL

Si no tienes WSL, ejecuta en PowerShell como administrador:

```powershell
wsl --install
```

Reinicia si lo solicita y completa la creacion de tu usuario de Ubuntu.
Si ya tienes Ubuntu en WSL, no necesitas reinstalarlo.

Necesitas Docker Engine con Compose dentro de Ubuntu WSL, o Docker Desktop
con el motor WSL 2 y la integracion habilitada para tu distribucion Ubuntu
(Settings > Resources > WSL Integration). No necesitas ambos motores.

Abre Ubuntu y comprueba que Docker puede acceder a su motor:

```bash
docker version
docker compose version
```

Instala Ansible y el soporte para autenticacion SSH por contrasena en Ubuntu:

```bash
sudo apt update
sudo apt install -y ansible sshpass
ansible --version
```

Todos los comandos siguientes, salvo que se indique PowerShell, se ejecutan
desde Ubuntu WSL, dentro de la carpeta del proyecto.

Si los archivos estan en esta carpeta de Windows, puedes acceder asi:

```bash
cd /mnt/c/Users/gbria/projects/homeworks/practia8
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
```

En otro equipo, ajusta la ruta a donde hayas descargado el proyecto.
La variable `ANSIBLE_CONFIG` selecciona explicitamente la configuracion:
Ansible puede ignorarla automaticamente en carpetas de Windows con permisos
de escritura para todos. Exportala de nuevo al abrir otra terminal.

## 2. Construir la imagen e iniciar los cinco servidores

```bash
docker compose config --quiet
docker compose build servidor1
docker compose up -d
docker compose ps
```

La imagen incluye SSH, Python para los modulos de Ansible, y el usuario
`ansible`, con contrasena `ansible` y sudo sin contrasena. Cada contenedor
genera sus propias claves de servidor SSH al iniciar por primera vez.

| Nombre en el inventario | IP de conexion | Puerto SSH | Usuario | Clave |
| --- | --- | --- | --- | --- |
| servidor1 | 127.0.0.1 | 2221 | ansible | ansible |
| servidor2 | 127.0.0.1 | 2222 | ansible | ansible |
| servidor3 | 127.0.0.1 | 2223 | ansible | ansible |
| servidor4 | 127.0.0.1 | 2224 | ansible | ansible |
| servidor5 | 127.0.0.1 | 2225 | ansible | ansible |

La IP es la del acceso local al motor Docker; cada puerto se redirige al
puerto 22 de un contenedor distinto. No dependemos de sus IP internas,
que pueden cambiar al recrearlos. No se publican puertos en toda la red.
Ejecuta Ansible en el mismo entorno WSL del motor Docker o de su integracion.

## 3. Comprobar inventario y conexion

```bash
ansible-inventory --graph
ansible-playbook playbook.yml --syntax-check
ansible-playbook verificar.yml --syntax-check
ansible servidores -m ansible.builtin.ping
```

El ping de Ansible comprueba SSH y Python (no es un ping ICMP).
Debes obtener `pong` en los cinco servidores. Si acabas de levantarlos y
todavia no responden, espera unos segundos y repite el ping; el playbook
principal espera automaticamente a que SSH este disponible.

## 4. Ejecutar la automatizacion

```bash
ansible-playbook playbook.yml
```

Tareas realizadas en cada servidor:

1. Actualizar la cache de APT si tiene mas de una hora o no existe.
2. Crear el usuario `itla`, con directorio personal y sin clave de acceso.
3. Crear `/home/itla/app`, propiedad de `itla`.
4. Crear `/home/itla/app/hola.txt` con el texto `Hola desde Ansible!`.
5. Instalar `cowsay` y `htop`.

## 5. Verificar los resultados

```bash
ansible-playbook verificar.yml
```

Este playbook comprueba que existen el usuario, la carpeta y el archivo,
su propietario, el contenido del archivo y ambos paquetes. Debe terminar
con `failed=0` y `unreachable=0` en los cinco servidores.

Para comprobar la idempotencia, repite la configuracion antes de que pase
una hora: si no ha habido cambios externos, debe mostrar `changed=0`.

```bash
ansible-playbook playbook.yml
```

Tambien puedes inspeccionar un servidor manualmente:

```bash
ssh -p 2221 ansible@127.0.0.1
id itla
sudo cat /home/itla/app/hola.txt
/usr/games/cowsay 'Practica completada'
htop
```

La clave SSH es `ansible`. Para salir de htop pulsa `q` y para salir del
servidor ejecuta `exit`. El comando `cowsay` puede requerir su ruta completa
porque Ubuntu lo instala en `/usr/games`.

## 6. Subir el codigo a GitHub

Crea un repositorio vacio en GitHub, sin README ni licencia inicial.
Desde la carpeta del proyecto ejecuta (reemplaza la URL):

```bash
git init
git add Dockerfile docker-compose.yml inventario.ini ansible.cfg playbook.yml verificar.yml README.md .gitignore .dockerignore
git commit -m "feat: agregar practica de Ansible con cinco servidores Ubuntu"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/practica8.git
git push -u origin main
```

Necesitas Git instalado, tu nombre y correo configurados y autenticarte
con GitHub. La contrasena normal de GitHub no sirve para un push HTTPS:
usa un gestor de credenciales o un token de acceso. No publiques tokens
ni claves reales; la clave incluida en el inventario es solo de laboratorio.

Entrega la URL del repositorio. Como evidencia, puedes adjuntar capturas
de `docker compose ps`, el ping y los resumenes de ambos playbooks.

## Detener o eliminar el laboratorio

Para detener conservando los cambios de los contenedores:

```bash
docker compose stop
```

Para iniciarlos de nuevo: `docker compose start`.

Para eliminar los contenedores y su red:

```bash
docker compose down
```

**Eliminar o recrear los contenedores borra los usuarios, archivos y paquetes
creados dentro.** Ejecuta nuevamente el playbook al crear otros contenedores.

## Problemas frecuentes

- **Docker no responde:** inicia Docker Desktop y habilita la integracion
  WSL, o inicia el servicio Docker si usas Engine dentro de WSL.
- **Puerto ocupado:** cambia el puerto publicado en `docker-compose.yml`
  y el `ansible_port` correspondiente en `inventario.ini`.
- **Ansible no lee el inventario:** entra en la carpeta del proyecto y ejecuta
  `export ANSIBLE_CONFIG="$PWD/ansible.cfg"`.
- **SSH no conecta:** revisa `docker compose ps` y `docker compose logs servidor1`.
  Con Docker Desktop comprueba la integracion WSL. Si tu configuracion de
  red no permite el acceso local desde WSL, usa Docker Engine dentro de WSL
  para que Ansible y los puertos publicados esten en el mismo entorno.
- **Falla APT:** los contenedores necesitan acceso a Internet y DNS funcional
  para descargar paquetes; revisa la conectividad de Docker y vuelve a ejecutar.

## Referencias

- [Instalacion de WSL](https://learn.microsoft.com/windows/wsl/install)
- [Docker Desktop y WSL](https://docs.docker.com/desktop/features/wsl/)
- [Inventarios de Ansible](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)
- [Modulo apt de Ansible](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
