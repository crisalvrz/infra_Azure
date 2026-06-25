# Despliegue Automatizado de Red Hub-and-Spoke Segura en Azure con Terraform

## 1. Descripción
La arquitectura implementa una topología de red en estrella (*Hub-and-Spoke*) compuesta por:
* **VNet Hub (Red Central):** Actúa como el núcleo de conectividad de la infraestructura (simulando una oficina central o zona perimetral/DMZ).
* **VNet Spoke (Red de Producción):** Aloja los recursos y aplicaciones de negocio aislados de accesos no autorizados.
* **VNet Peering:** Interconexión directa y bidireccional que comunica ambas redes a través del *backbone* privado de alta velocidad de Microsoft, sin necesidad de exponer tráfico a la internet pública.
* **Network Security Group (NSG):** Firewall por software perimetral asociado a la subred del *Spoke* para restringir el tráfico entrante de manera estricta.

### Importancia Estratégica y Metodología DevOps (NetDevOps)

En entornos corporativos, desplegar una arquitectura *Hub-and-Spoke* de forma manual en el portal web es un antipatrón. Este proyecto adopta la metodología **DevOps** (tratando las redes como si fueran software) para garantizar un ciclo de vida eficiente, seguro y automatizado basado en cuatro pilares:

**Infraestructura como Código (IaC):**
   Todo el diseño de red está definido en archivos de configuración declarativos utilizando **Terraform**. Esto permite versionar la infraestructura en Git, facilitando la auditoría de cambios, el trabajo en equipo y eliminando por completo el factor del error humano o el "drift" (desviación) de configuración típico de los despliegues manuales.

**Idempotencia y Repetibilidad del Entorno:**
   Gracias al pipeline de Terraform (`init` -> `validate` -> `plan` -> `apply`), el despliegue es completamente idempotente. Podemos replicar exactamente esta misma topología e ID de red en entornos de Desarrollo, Preproducción o Producción en cuestión de segundos, garantizando un comportamiento idéntico en cualquier fase.

**Seguridad Integrada (DevSecOps y Zero Trust):**
   La seguridad no es una capa posterior, sino que se define en el código desde el primer minuto. Se rompe el concepto de red plana tradicional aplicando aislamiento total entre VNets. Mediante los Network Security Groups (NSG), se implementa el principio de mínimo privilegio, bloqueando todo el tráfico entrante por defecto y abriendo exclusivamente los puertos web requeridos (**HTTP 80** y **HTTPS 443**).

**Optimización y Programación Dinámica de Red:**
   Huyendo de las configuraciones estáticas (*hardcoding*), el direccionamiento IP se calcula en tiempo de ejecución. El uso de funciones nativas como `cidrsubnet()` permite que la infraestructura escale de forma inteligente y automatizada, recalculando las subredes de manera dinámica en función de las variables de entrada.
---

## 2. Guía

### Fase 1: Preparación del Entorno Local
Instalación de la interfaz de línea de comandos de Azure y descarga del binario nativo de Terraform para configurar las variables de entorno en el sistema.

#### Actualización del sistema e instalación de dependencias

sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip gnupg software-properties-common

#### Instalación de Azure CLI

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#### Instalación de Terraform

#### 1. Descargar la clave GPG de HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

#### 2. Añadir el repositorio oficial
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

#### 3. Instalar el binario
sudo apt update && sudo apt install terraform -y

### Gestión de Archivos y Carpetas (Estructura Monorrepo)

#### Volver a tu carpeta de usuario
cd ~

#### Crear la carpeta principal del repositorio general
mkdir infra_azure
cd infra_azure

#### Crear la subcarpeta específica para este primer ejercicio
mkdir 01-hub-spoke-nsg

#### Mover tus archivos .tf a la nueva estructura (ajusta la ruta de origen si cambia)
cp ~/proyecto-hubspoke/*.tf ~/infra_azure/01-hub-spoke-nsg/

#### Ver archivos ocultos y comprobar la estructura
ls -la


### Fase 2: Autenticación en el Cloud
Inicio de sesión y vinculación de la sesión local con la suscripción de Azure:

#### Iniciar sesión desde la terminal (abre el navegador de Ubuntu)
az login

#### Listar tus suscripciones activas (por si tienes más de una)
az account list --output table


### Fase 3: Estructuración de Archivos (Buenas Prácticas DevOps)

En lugar de crear un único archivo monolítico, el código se ha modularizado y desacoplado profesionalmente en tres componentes:

providers.tf: Define los requerimientos del proveedor azurerm.
variables.tf: Parametrización de rangos CIDR y localización geográfica.
main.tf: Declaración de la lógica de recursos de Azure (VNets, Peerings y NSG).


### Fase 4: Ciclo de Vida de Terraform

Ejecución de los comandos estándar para formatear, inicializar, validar, planificar y desplegar la infraestructura de forma
segura:

  1. Formatear el código según las guías de estilo de HashiCorp
terraform fmt
  2. Inicializar el entorno descargando los plugins necesarios de Azure
terraform init
  3. Validar sintácticamente que no existan errores en los archivos
terraform validate
  4. Simular y previsualizar los cambios antes de aplicarlos
terraform plan
  5. Aplicar el despliegue
terraform apply

### Fase 5: Auditoría y Destrucción de Recursos

Verificación en el Portal de Azure del correcto aprovisionamiento de las redes, comprobando el estado Connected del peering y la tabla de reglas de entrada del NSG. Al finalizar las pruebas, se liberan los recursos para mantener los costes a 0 €:

terraform destroy
