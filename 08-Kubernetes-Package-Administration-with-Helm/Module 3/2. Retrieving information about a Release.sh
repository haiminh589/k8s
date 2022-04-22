###################################################################################################
###################################################################################################
#
#
# Module 3 of Kubernetes Package Administration with Helm
# 
# Retrieving information about a Release
#  
# 
###################################################################################################
###################################################################################################



# view deployments
helm list



# view status of release
helm status mysql



# get release manifests
helm get manifest mysql > manifests.txt



# get release values - no user values were supplied so file will be blank
helm get values mysql > values.txt



# get release notes
helm get notes mysql > notes.txt



# get all from release
helm get all mysql  > all.txt



# view kubernetes objects
kubectl get all




# view release history
helm history mysql



# uninstall a release
helm uninstall mysql --keep-history



# confirm
helm list



# confirm with --all flag
helm list --all



# delete release
helm delete mysql



# confirm with --all flag
helm list --all