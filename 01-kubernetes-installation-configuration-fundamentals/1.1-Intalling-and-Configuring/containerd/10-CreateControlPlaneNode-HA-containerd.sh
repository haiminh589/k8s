###IMPORTANT###
#If you are using containerd, make sure docker isn't installed. 
#kubeadm init will try to auto detect the container runtime and at the moment 
#it if both are installed it will pick docker first.
ssh aen@c1-cp1


#0 - Creating a Cluster
#Create our kubernetes cluster, specify a pod network range matching that in calico.yaml! 
#Only on the Control Plane Node, download the yaml files for the pod network.
wget https://docs.projectcalico.org/manifests/calico.yaml


#Look inside calico.yaml and find the setting for Pod Network IP address range CALICO_IPV4POOL_CIDR, 
#adjust if needed for your infrastructure to ensure that the Pod network IP
#range doesn't overlap with other networks in our infrastructure.
vi calico.yaml


#Generate a default kubeadm init configuration file...this defines the settings of the cluster being built.
#If you get a warning about how docker is not installed...this is OK to ingore and is a bug in kubeadm
#For more info on kubeconfig configuration files see: 
#    https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file
kubeadm config print init-defaults | tee ClusterConfiguration.yaml


#Inside default configuration file, we need to change four things.
#1. The IP Endpoint for the API Server localAPIEndpoint.advertiseAddress:
#2. nodeRegistration.criSocket from docker to containerd
#3. Set the cgroup driver for the kubelet to systemd, it's not set in this file yet, the default is cgroupfs
#4. Edit kubernetesVersion to match the version you installed in 0-PackageInstallation-containerd.sh
#5. Update the node name from node to the actual control plane node name, c1-cp1

#Change the address of the localAPIEndpoint.advertiseAddress to the Control Plane Node's IP address
sed -i 's/  advertiseAddress: 1.2.3.4/  advertiseAddress: 172.16.94.10/' ClusterConfiguration.yaml

#Set the CRI Socket to point to containerd
sed -i 's/  criSocket: \/var\/run\/dockershim\.sock/  criSocket: \/run\/containerd\/containerd\.sock/' ClusterConfiguration.yaml

#UPDATE: Added configuration to set the node name for the control plane node to the actual hostname
sed -i 's/  name: node/  name: c1-cp1/' ClusterConfiguration.yaml

#Set the cgroupDriver to systemd...matching that of your container runtime, containerd
cat <<EOF | cat >> ClusterConfiguration.yaml
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF


#Review the Cluster configuration file, update the version to match what you've installed. 
#We're using 1.21.0...if you're using a newer version update that here.
vi ClusterConfiguration.yaml


#Need to add CRI socket since there's a check for docker in the kubeadm init process, 
#if you don't you'll get this error...
#   error execution phase preflight: docker is required for container runtime: exec: "docker": executable file not found in $PATH
#On c1-cp1 - Leader Master
sudo kubeadm init \
    --config=ClusterConfiguration.yaml \
    --cri-socket /run/containerd/containerd.sock \
    --upload-certs


#Before moving on review the output of the cluster creation process including the kubeadm init phases, 
#the admin.conf setup and the node join command

#On c1-cp1, c1-cp2 & c1-cp3
#172.16.94.7 is HA-Proxy
kubeadm join 172.16.94.7:6443 --token abcdef.0123456789abcdef /
        --discovery-token-ca-cert-hash sha256:de383398f6390bcb7726176e4344f7bf2ba226de6a017866f00b55c381bc6794 /
        --control-plane /
        --certificate-key 96b9a1bf447eac4260cc4519e6174b8a35f8696b8b70919cb471c4957cb48969 /
        --apiserver-advertise-address=172.16.94.X

#Configure our account on the Control Plane Node to have admin access to the API server from a non-privileged account.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#1 - Creating a Pod Network
#Deploy yaml file for your pod network. #May print a warning about PodDisruptionBudget it is safe to ignore for now.
kubectl apply -f calico.yaml


#Look for the all the system pods and calico pods to change to Running. 
#The DNS pod won't start (pending) until the Pod network is deployed and Running.
kubectl get pods --all-namespaces


#Gives you output over time, rather than repainting the screen on each iteration.
kubectl get pods --all-namespaces --watch


#All system pods should be Running
kubectl get pods --all-namespaces


#Get a list of our current nodes, just the Control Plane Node/Master Node...should be Ready.
kubectl get nodes 




#2 - systemd Units...again!
#Check out the systemd unit...it's no longer crashlooping because it has static pods to start
#Remember the kubelet starts the static pods, and thus the control plane pods
sudo systemctl status kubelet.service 


#3 - Static Pod manifests
#Let's check out the static pod manifests on the Control Plane Node
ls /etc/kubernetes/manifests


#And look more closely at API server and etcd's manifest.
sudo more /etc/kubernetes/manifests/etcd.yaml
sudo more /etc/kubernetes/manifests/kube-apiserver.yaml


#Check out the directory where the kubeconfig files live for each of the control plane pods.
ls /etc/kubernetes


##HA=Proxy setup
#Install HA-Proxy
sudo apt update && sudo apt install -y haproxy

#Edit haproxy config file & paste all these lines at the bottom of file
sudo vim /etc/haproxy/haproxy.cfg

frontend kubernetes-frontend
    bind 172.16.94.7:6443   #haproxy machine IP
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    option tcp-check
    balance roundrobin
    server c1-cp1 172.16.94.10:6443 check fall 3 rise 2
    server c1-cp2 172.16.94.9:6443 check fall 3 rise 2
    server c1-cp3 172.16.94.8:6443 check fall 3 rise 2

#Restart haproxy service
systemctl restart haproxy