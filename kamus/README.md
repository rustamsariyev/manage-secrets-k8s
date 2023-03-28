# manage-secrets-k8s

An open source, GitOps, zero-trust secrets encryption and decryption solution for Kubernetes applications. Kamus enable users to easily encrypt secrets than can be decrypted only by the application running on Kubernetes. The encryption is done using strong encryption providers (currently supported: Azure KeyVault, Google Cloud KMS, Amazon Web Services KMS and AES). To learn more about Kamus, check out the blog post and a talk from AppSec California 2019.

# Research 
One of our clients is running Kubernetes on AWS (EKS + Terraform). At the moment, they store secrets like database passwords in a configuration file of the application, which is stored along with the code in Github. The resulting application pod is getting an ENV variable with the name of the environment, like staging or production, and the configuration file loads the relevant secrets for that environment.

We would like to help them improve the way they work with this kind of sensitive data.

Please also note that they have a small team and their capacity for self-hosted solutions is limited.

Provide one or two options for how would you propose them to change how they save and manage their secrets.

# Solution 

https://kamus.soluto.io/