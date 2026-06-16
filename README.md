# TP Kubernetes K3d — Packer & Ansible

## Prérequis
- GitHub Codespace
- Docker
- kubectl, k3d, Packer, Ansible

---

## Séquence 1 : Fork et Codespace

1. Forker ce repository
2. Depuis l'onglet **CODE** de votre fork, ouvrir un **Codespace GitHub**

---

## Séquence 2 : Création du cluster K3d

### Installer K3d
```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

### Créer le cluster
```bash
k3d cluster create lab \
  --servers 1 \
  --agents 2
```

### Vérifier le cluster
```bash
kubectl get nodes
```

### Déployer Mario (test)
```bash
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
```
Onglet **PORTS** → rendre public le port **8080** → ouvrir l'URL.

---

## Séquence 3 : Image custom Nginx avec Packer et Ansible

### 1. Installer Packer et Ansible
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y packer ansible
```

### 2. Build de l'image avec Packer
```bash
cd packer
packer init .
packer build nginx.pkr.hcl
```

### 3. Import de l'image dans K3d
```bash
cd ..
k3d image import custom-nginx:latest -c lab
```

### 4. Déploiement via Ansible
```bash
pip install kubernetes --break-system-packages
ansible-galaxy collection install kubernetes.core
ansible-playbook ansible/deploy.yml -e "ansible_python_interpreter=/home/codespace/.python/current/bin/python3"
```

### 5. Forward du port et accès
```bash
kubectl port-forward svc/custom-nginx-svc 8081:80 >/tmp/nginx.log 2>&1 &
```
Onglet **PORTS** → rendre public le port **8081** → ouvrir l'URL.

---

## Automatisation via Makefile

```bash
make all        # lance tout d'un coup
make cluster    # crée le cluster K3d
make build      # build l'image Packer
make import     # importe l'image dans K3d
make deploy     # déploie via Ansible
make forward    # forward le port 8081
```

---

## Architecture du projet

```
Image_to_Cluster/
├── ansible/
│   └── deploy.yml
├── packer/
│   └── nginx.pkr.hcl
├── index.html
├── Makefile
└── README.md
```

---

## Stack technique
- **Packer** : build de l'image Docker custom (Nginx + index.html)
- **Ansible** : déploiement Kubernetes déclaratif
- **K3d** : cluster Kubernetes léger dans GitHub Codespace
- **Nginx** : serveur web de base