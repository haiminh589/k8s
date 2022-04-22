ssh aen@c1-cp1
cd ~/k8s-advance-course/05-configuring-managing-kubernetes-networking-services-ingress/5.1-Kubernetes-Networking-Fundamentals


#1. Investigating the Cluster DNS Service
#It's Deployed as a Service in the cluster with a Deployment in the kube-system namespace
kubectl get service --namespace kube-system


#Two Replicas, Args injecting the location of the config file which is backed by ConfigMap mounted as a Volume.
kubectl describe deployment coredns --namespace kube-system | more
 

#The configmap defining the CoreDNS configuration and we can see the default forwarder is /etc/resolv.conf
kubectl get configmaps --namespace kube-system coredns -o yaml | more




#2. Configuring CoreDNS to use custom Forwarders, spaces not tabs!
#Defaults use the nodes DNS Servers for fowarders
#Replaces forward . /etc/resolv.conf
#with forward . 1.1.1.1
#Add a conditional domain forwarder for a specific domain
#ConfigMap will take a second to update the mapped file and the config to be reloaded
kubectl apply -f CoreDNSConfigCustom.yaml --namespace kube-system


#How will we know when the core dns configuration file is updated in the pod?
#You can tail the log looking for the reload the configuration file...this can take a minute or two
#Also look for any errors post configuration
kubectl logs --namespace kube-system --selector 'k8s-app=kube-dns' --follow 


#Run some DNS queries against the kube-dns service cluster ip to ensure everything works...
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{ .spec.clusterIP }')
nslookup www.youtube.com $SERVICEIP
nslookup www.google.com $SERVICEIP


#On c1-cp1, let's put the default configuration back, using . forward /etc/resolv.conf 
kubectl apply -f CoreDNSConfigDefault.yaml --namespace kube-system



#3. Configuring Pod DNS client Configuration
kubectl apply -f DeploymentCustomDns.yaml


#Let's check the DNS configuration of a Pod created with that configuration
#This line will grab the first pod matching the defined selector
PODNAME=$(kubectl get pods --selector=app=hello-world-customdns -o jsonpath='{ .items[0].metadata.name }')
echo $PODNAME
kubectl exec -it $PODNAME -- cat /etc/resolv.conf


#Clean up our resources
kubectl delete -f DeploymentCustomDns.yaml



#TODO for the viewer...
#Demo 1 - let's get a pods DNS A record and a Services A record
#Create a deployment and a service
kubectl apply -f deployment.yaml

#Get the pods and their IP addresses
kubectl get pods -o wide

#For one of the pods replace the dots in the IP addres with dashes for example10.10.244.222.217 becomes 10-244-222-217
#There's more on service A records in the next demo
nslookup 10-244-222-217.default.pod.cluster.local  $SERVICEIP
nslookup hello-world.default.svc.cluster.local $SERVICEIP

#Clean up our resources
kubectl delete -f deployment.yaml


#Demo 2 - you can use this technique to verify your DNS forwarder configuration above.
#Logging in CoreDNS will log the query, but not which forwarder it was sent to. 
#We can use tcpdump to listen to the packets on the wire to see where the DNS queries are being sent to.

#Find the name of a Node running one of the DNS Pods running...so we're going to observe DNS queries there.
DNSPODNODENAME=$(kubectl get pods --namespace kube-system --selector=k8s-app=kube-dns -o jsonpath='{ .items[0].spec.nodeName }')
echo $DNSPODNODENAME


#Let's log into THAT node running the dns pod and start a tcpdump to watch our dns queries in action.
#Your interface (-i) name may be different
ssh aen@$DNSPODNODENAME
sudo tcpdump -i enp0s3 port 53 -n 


#In a second terminal, let's test our DNS configuration from a pod to make sure we're using the configured forwarder.
#When this pod starts, it will point to our cluster dns service.
#Install dnsutils for nslookup and dig
ssh aen@c1-cp1
kubectl run -it --rm debian --image=debian
apt-get update && apt-get install dnsutils -y


#In our debian pod let's look at the dns config and run two test DNS queries
#The nameserver will be your cluster dns service cluster ip.
#We'll query two domains to generate traffic for our tcpdump
cat /etc/resolv.conf
nslookup www.youtube.com
nslookup www.google.com


#Switch back to our second terminal and review the tcpdump, confirming each query is going to the correct forwarder
# IP 10.0.2.15.3821 > 10.0.2.3.53: 11212+ [1au] AAAA? youtube-ui.l.google.com. (52)
#IP 10.0.2.3.53 > 10.0.2.15.3821: 11212 NXDomain 0/0/1 (52)

#Exit the tcpdump
ctrl+c


#Log out of the node, back onto c1-cp1
exit


#Switch sessions and break out of our pod and it will be deleted.
exit


#Exit out of our second SSH session and get a shell back on c1-cp1
exit

