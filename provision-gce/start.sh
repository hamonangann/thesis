# PRASYARAT: gcloud SDK, terraform, kubectl
# Disarankan menggunakan Cloud Shell agar tidak perlu instal manual

# Set zona

#! /bin/bash
gcloud config set compute/zone us-west1-a

# Buat mesin klaster dan mesin klien
terraform init
terraform apply -var "project=$(gcloud config get-value project)"

# Buat berkas SSH
gcloud compute config-ssh

# Instalasi master node dengan K3sup
MASTER_IP=$(gcloud compute instances describe gce-master-node | grep -oP "natIP: \K.*")
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
k3sup install --ip $MASTER_IP --context k3s --ssh-key ~/.ssh/google_compute_engine --user $(whoami)

# Instalasi worker node
WORKER_IP=$(gcloud compute instances describe gce-worker-node | grep -oP "natIP: \K.*")
k3sup join --ip $WORKER_IP --server-ip $MASTER_IP --context k3s --ssh-key ~/.ssh/google_compute_engine --user $(whoami)

# Dapatkan kredensial klaster untuk kubectl
export KUBECONFIG=`pwd`/kubeconfig

# Salin kredensial klaster ke client
gcloud compute scp kubeconfig $(whoami)@client:/tmp
gcloud compute ssh client --command='sudo sh -c "echo export KUBECONFIG=/tmp/kubeconfig >> /etc/profile"'

# Mencegah pod dideploy ke master node
kubectl taint node gce-master-node node-role.kubernetes.io/master:NoSchedule

# Instalasi load balancer
kubectl apply -f ../cluster/service.yaml
EOF