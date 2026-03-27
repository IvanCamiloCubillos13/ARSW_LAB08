# Lab 8 — Infraestructura como Código con Terraform (Azure)

**Curso:** ARSW / BluePrints  
**Equipo:** Yojhan Toro, Ivan Cubillos
**Fecha:** 2026

## Descripción

Despliegue de una arquitectura de alta disponibilidad en Azure usando Terraform. 
Incluye un Load Balancer público, 2 VMs Linux con nginx, red virtual segmentada 
en subredes y NSGs, y estado remoto en Azure Storage.

## Arquitectura

- **Resource Group:** `lab8-rg`
- **VNet:** `lab8-vnet` (10.10.0.0/16)
  - `subnet-web` (10.10.1.0/24) — VMs detrás del Load Balancer
  - `subnet-mgmt` (10.10.2.0/24) — acceso de gestión
- **NSG web:** permite HTTP (80) desde Internet y SSH (22) solo desde IP autorizada
- **NSG mgmt:** permite SSH (22) solo desde IP autorizada
- **Load Balancer:** SKU Standard, IP pública estática, health probe TCP/80
- **VMs:** Ubuntu 22.04 LTS, nginx instalado via cloud-init
- **Remote State:** Azure Storage Account con bloqueo de estado

## Estructura del repositorio
```
LAB08/
├── infra/
│   ├── main.tf           # Resource Group y wiring de módulos
│   ├── providers.tf      # Provider AzureRM y backend
│   ├── variables.tf      # Declaración de variables
│   ├── outputs.tf        # Outputs (IP pública, nombres VMs)
│   ├── cloud-init.yaml   # Instalación de nginx
│   ├── backend.hcl.example
│   └── env/
│       └── dev.tfvars
├── modules/
│   ├── vnet/             # Red, subredes y NSGs
│   ├── compute/          # NICs y VMs
│   └── lb/               # Load Balancer
└── .github/workflows/    # CI/CD con GitHub Actions
```

## Cómo desplegar

### Prerrequisitos
- Azure CLI instalado y sesión activa (`az login`)
- Terraform >= 1.6
- Clave SSH generada en `~/.ssh/id_ed25519`

### 1. Bootstrap del backend remoto
```bash
az group create -n rg-tfstate-lab8 -l eastus
az storage account create -g rg-tfstate-lab8 -n <nombre-unico> -l eastus --sku Standard_LRS
az storage container create --name tfstate --account-name <nombre-unico>
```

### 2. Configurar variables
Copia `backend.hcl.example` a `backend.hcl` y completa los valores.  
En `env/dev.tfvars` actualiza tu IP pública y alias.

### 3. Inicializar y desplegar
```bash
cd infra
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -var-file=env/dev.tfvars -out plan.tfplan
terraform apply plan.tfplan
```

### 4. Verificar
```bash
curl http://$(terraform output -raw lb_public_ip)
```

### 5. Destruir al terminar
```bash
terraform destroy -var-file=env/dev.tfvars
```

## Seguridad

- Acceso SSH restringido por IP (`allow_ssh_from_cidr`)
- Sin contraseñas — solo autenticación por clave SSH
- NSG con regla explícita Deny-All al final
- Estado remoto con bloqueo para evitar conflictos en equipo
- `backend.hcl` excluido del repositorio (`.gitignore`)

## Estimación de costos

Costos aproximados si la infraestructura permaneciera activa un mes completo
en la región `eastus`:

| Recurso | Tipo | Costo aprox/mes |
|---|---|---|
| 2× VM `Standard_B1s` | 1 vCPU, 1 GB RAM | ~$30 USD |
| Load Balancer Standard | por regla + datos procesados | ~$18 USD |
| 2× Public IP Standard | IPs estáticas | ~$7 USD |
| 2× Disco OS Standard HDD | 30 GB c/u | ~$5 USD |
| Storage Account (state) | LRS, uso mínimo | ~$1 USD |
| **Total estimado** | | **~$61 USD/mes** |

> **Para este lab el costo real es menor a $1 USD**, ya que los recursos
> solo permanecen activos durante la sesión de trabajo. Es obligatorio
> ejecutar `terraform destroy` al finalizar para evitar cargos innecesarios.

Referencia: [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator)