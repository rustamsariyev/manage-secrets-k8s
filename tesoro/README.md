# manage-secrets-k8s
# Kapitan Secrets Controller for Kubernetes
# Research 
One of our clients is running Kubernetes on AWS (EKS + Terraform). At the moment, they store secrets like database passwords in a configuration file of the application, which is stored along with the code in Github. The resulting application pod is getting an ENV variable with the name of the environment, like staging or production, and the configuration file loads the relevant secrets for that environment.

We would like to help them improve the way they work with this kind of sensitive data.

Please also note that they have a small team and their capacity for self-hosted solutions is limited.

Provide one or two options for how would you propose them to change how they save and manage their secrets.

# Solution 
Tesoro allows you to seamlessly apply Kubernetes manifests with Kapitan secret refs. As it runs in the cluster, it will reveal embedded Kapitan secret refs when they are applied. It supports all types of Kapitan secrets backends: AWS KMS, GCP KMS, Vault with more coming up.

https://github.com/kapicorp/tesoro