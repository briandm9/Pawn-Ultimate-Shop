# 🛒 Ultimate Shop - Tienda para CS 1.6 (AMXX)

**Ultimate Shop** es una tienda de skins para servidores de **Counter-Strike 1.6**, desarrollada en **Pawn** para **AMX Mod X**.  
Permite a los jugadores comprar ítems cosméticos como hats, modelos de jugador, cuchillos y trails, usando un sistema de puntos persistente.

---

## 🎥 Gameplay

[![Ultimate Shop - Gameplay](https://img.youtube.com/vi/wiNfSG-_Rqg/0.jpg)](https://www.youtube.com/watch?v=wiNfSG-_Rqg)

👉 Mirá el plugin en acción en este video de demostración.

---

## 🎮 Características

- 🎩 **Hats / Sombreros** personalizables  
- 🧍‍♂️ **Player Models / Skins** desbloqueables  
- 🔪 **Cuchillos** cosméticos  
- 🌠 **Trails / Estelas de colores** al correr  
- 💾 **Guardado de datos** automático en **MySQL** o **SQLite**  
- 🪙 **Sistema de puntos**: los jugadores ganan puntos y los gastan en la tienda  
- 📋 Menú de tienda fácil de usar con sistema modular (uso: letra N o "nightvision")  
- ⚙️ Soporte para hasta **35 ítems** por cada categoría (hats, models, knives, trails), configurable desde el `.sma`

---

## 🛠 Requisitos

- **AMX Mod X 1.9 o superior**  
- Módulo `sqlite` o `mysql` activado, según el sistema de guardado que se use

---

## ⚙ Instalación

1. Copiá los archivos `.sma` en la carpeta `addons/amxmodx/scripting/`  
2. Compilá el plugin y colocá el `.amxx` resultante en `addons/amxmodx/plugins/`  
3. Añadí el nombre del plugin en `configs/plugins.ini`  
4. Activá el módulo correspondiente en `configs/modules.ini`:  
   - Para SQLite: descomentá `sqlite`  
   - Para MySQL: descomentá `mysql`  
5. Si usás **MySQL**, importá la estructura de tabla que se encuentra al final del archivo `.sma`

---

## ⚙️ Configuración de la base de datos

En la parte superior del `.sma` vas a encontrar las siguientes definiciones, que debés editar si usás MySQL:

#define SQL_HOST    "127.0.0.1"  
#define SQL_USER    "root"  
#define SQL_PASS    ""  
#define SQL_DBNAME  "ultimate_shop"  
#define SQL_DBTABLE "jugadores"  

---

## 🖼 Configuración de imágenes para cuchillos

En el `.sma`, también vas a encontrar esta línea:

#define knifeurl "http://tuweb.com/knifes"

🎨 Esta línea define la **URL base** donde están alojadas las imágenes de los cuchillos que se mostrarán en el menú.

📂 **Importante:**

- Las imágenes deben estar en **formato `.jpg`**  
- El nombre del archivo debe coincidir exactamente con el nombre del cuchillo  
- No uses espacios; usá guiones bajos o quitá los espacios directamente  

✅ **Ejemplo:**  
Si agregás un cuchillo llamado `"Karambit"` en la configuración del plugin, el sistema buscará esta imagen:

http://tuweb.com/knifes/Karambit.jpg

---

## ⚠️ Recomendaciones importantes

Este plugin no otorga puntos automáticamente. En su lugar, expone una native para que otros plugins puedan entregar puntos a los jugadores:

native_puntos(id, cant);

Se recomienda crear un plugin adicional que otorgue puntos por acciones como:

- Matar enemigos  
- Plantar o desactivar la bomba  
- Ganar rondas  
- Realizar objetivos del mapa, etc.

---

## 🧾 Guardado por nombre de jugador

El plugin guarda los datos utilizando el **nombre del jugador** como identificador.  
Se recomienda utilizar un sistema de cuentas aparte, como:

- Registro manual con contraseña  
- Integración con SteamID  
- Otro sistema de identificación persistente  

✅ Esto ayuda a **proteger los datos de los jugadores** y evitar pérdidas por cambios de nombre.

---
