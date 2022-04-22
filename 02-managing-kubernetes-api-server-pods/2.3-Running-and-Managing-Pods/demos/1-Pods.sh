ssh aen@c1-cp1
cd ~/Kubernetes-Advance-Course/02-managing-kubernetes-api-server-pods/2.3-Running-and-Managing-Pods/demos

#Start up kubectl get events --watch and background it.
kubectl get events --watch &

#Create a pod...we can see the scheduling, container pulling and container starting.
kubectl apply -f pod.yaml

#Start a Deployment with 1 replica. We see the deployment created, scaling the replica set and the replica set starting the first pod
kubectl apply -f deployment.yaml

#Scale a Deployment to 2 replicas. We see the scaling the replica set and the replica set starting the second pod
kubectl scale deployment hello-world --replicas=2

#We start off with the replica set scaling to 1, then  Pod deletion, then the Pod killing the container 
kubectl scale deployment hello-world --replicas=1

kubectl get pods

#Let's use exec a command inside our container, we can see the GET and POST API requests through the API server to reach the pod.
kubectl -v 6 exec -it hello-world-54575d5b77-q6g8x -- /bin/sh
ps
exit

#Let's look at the running container/pod from the process level on a Node.
kubectl get pods -o wide
ssh aen@c1-node[xx]
ps -aux | grep hello-app
exit

#Now, let's access our Pod's application directly, without a service and also off the Pod network.
kubectl port-forward hello-world-54575d5b77-q6g8x 80:8080

#Let's do it again, but this time with a non-priviledged port
kubectl port-forward hello-world-54575d5b77-q6g8x 8080:8080 &

#We can point curl to localhost, and kubectl port-forward will send the traffic through the API server to the Pod
curl http://localhost:8080

#Kill our port forward session.
fg
ctrl+c

kubectl delete deployment hello-world
kubectl delete pod hello-world-pod

#Kill off the kubectl get events
fg
ctrl+c


#Static pods
#Quickly create a Pod manifest using kubectl run with dry-run and -o yaml...copy that into your clipboard
kubectl run hello-world --image=gcr.io/google-samples/hello-app:2.0 --dry-run=client -o yaml --port=8080 

#Log into a node...
ssh aen@c1-node1

#Find the staticPodPath:
sudo cat /var/lib/kubelet/config.yaml


#Create a Pod manifest in the staticPodPath...paste in the manifest we created above
sudo vi /etc/kubernetes/manifests/mypod.yaml
ls /etc/kubernetes/manifests

#Log out of c1-node1 and back onto c1-cp1
exit

#Get a listing of pods...the pods name is podname + node name
kubectl get pods -o wide


#Try to delete the pod...
kubectl delete pod hello-world-c1-node1


#Its still there...
kubectl get pods 


#Remove the static pod manifest on the node
ssh aen@c1-node1
sudo rm /etc/kubernetes/manifests/mypod.yaml

#Log out of c1-node1 and back onto c1-cp1
exit

#The pod is now gone.
kubectl get pods 
