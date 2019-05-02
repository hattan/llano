# llano
Demo Application deploying Ubuntu/ Apache to Kubernetes and mounting content via Azure File Storage

### Ubuntu Base Image
This repo uses an ubuntu image and configures Apache and PHP, thus creating a custom base image that is used by the app.
[Base Image DockerFile](base/Dockerfile)

### Requirements
* [az cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)

#### While there is a lot of manual steps here, almost all will be automated via build pipelines
This application consists of several bits: 

* Infrastructure - the terraform scripts needed to bring up the infrastructure.
  <br/> Note: the role assignment in terraform does not work, you have use the [included shell script](infrastructure/kubernetes/aks_acr_link.sh).
  <br/> To Install the Infrastructure:
  * ```terraform init```
  * ```terraform plan --out=plan```
  * ```terraform apply "plan"```
  * Run the [iaks_acr_link.sh file](infrastructure/kubernetes/aks_acr_link.sh)
  * Run the following to configure helm
    * ```kubectl create serviceaccount --namespace kube-system tiller```
    * ```kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller```
    * ```helm init --service-account tiller```
  * Install the Nginx Ingress 
    * helm install stable/nginx-ingress --namespace kube-system --set controller.replicaCount=2
  *  Get external IP of nginx-ingress
    * ```kubectl get svc --all-namespaces  | grep LoadBalancer | grep -v 'addon-http-application-routing-nginx-ingress'```
    * Get the Service Principal for the ip from the last step ```az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '<ip here>')].[id]" --output tsv
    * Add a dns entry for that ip ```az network': az network public-ip update --ids <service_principle_id> --dns-name <dns_prefix>```
    * Update [site/values.yaml](app/site/values.yaml) host to be the url received in the last step.
    
* Building the Base Image
  * Navigate to the [base directory](/base)
  * Build the image via ```docker build -t llano3e58acr.azurecr.io/unapache``` 
  * Push to ACR via ```docker push llano3e58acr.azurecr.io/unapache```
  
* Building the App (note the app uses the base image created in the previous step)
  * Navigate to the [app directory](/app)
  * Build the image via ```docker build -t llano3e58acr.azurecr.io/unapp``` 
  * Push to ACR via ```docker push llano3e58acr.azurecr.io/unapp```

* Create a storage account either through the Azure Portal or CLI (CLI instructions [here](https://docs.microsoft.com/en-us/azure/aks/azure-files-volume)
* Add a new File Share named 'sites' and within it add a folder called 'site1'
* Change the content of [index.html](app/www/html/index.html) to reflect it's on Azure
* Upload [index.html](app/www/html/index.html) to sites/site1 (share/folder).
* Deploy a new site via helm 
  * helm install site --name site --set site.folder=site1




### Useful commands

* Verify cluster is running and you are connected: ```kubectl get pods --all namespaces``` 
* See running pods after a deploment ```kubectl get pods```
* See services ```kubectl get svc```
* See ingresses ```kubectl get ingresses```
* describe a pod ```kubectr describe pod <pod_name>``` (pod name can be found via get pods)
* helm list ```helm ls```
* helm delete ``` helm del --purge <name>``` (name can be found in helm list)
* az acr show tags for an image ```az acr repository show-tags -n <acr_name> --repository <image>```
* configure local kubectl via az ```az aks get-credentials --resource-group php-poc --name poccluster``` (note create.sh runs this for you)  

### Resources

* [Manually create and use a volume with Azure Files share in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/azure-files-volume)
* [Kubernetes Volumes + Subpath](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath)
