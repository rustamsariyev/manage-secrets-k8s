# manage-secrets-k8s
# Terraform module for vault and consul located in tf-module directory.
This module used by terragrunt. 
https://github.com/rustamsariyev/eks-terragrunt/blob/main/demo_account/eu-central-1/prod/vault/terragrunt.hcl


# Research 
One of our clients is running Kubernetes on AWS (EKS + Terraform). At the moment, they store secrets like database passwords in a configuration file of the application, which is stored along with the code in Github. The resulting application pod is getting an ENV variable with the name of the environment, like staging or production, and the configuration file loads the relevant secrets for that environment.

We would like to help them improve the way they work with this kind of sensitive data.

Please also note that they have a small team and their capacity for self-hosted solutions is limited.

Provide one or two options for how would you propose them to change how they save and manage their secrets.

# Solution 
HashiCorp Vault with High-Availability (HA) mode. A cluster of Vault servers that use an HA storage backend as Consul.
Vault can be used to securely inject secrets like database credentials into running Pods in Kubernetes so that your application can access them

# What is HashiCorp Vault?
HashiCorp Vault is a secret management tool that is used to store sensitive values and access it securely. A secret can be anything, such as API encryption keys, passwords, or certificates. Vault provides encryption services and supports authentication and authorization.

We can run Vault in high-availability (HA) mode and standalone mode. The standalone mode runs a single Vault server which is less secure and less resilient that is not recommended for production grade setup.

Benefit of using HashiCorp Vault in HA using Raft
Vault can run in the multi-server mode for high availability to protect against outages. To persist the encrypted data, Vault supports many storage backends like Consul, MySQL, DynamoDB, etc.


Vault can be deployed into Kubernetes using the official HashiCorp Vault Helm chart. The Helm chart allows users to deploy Vault in various configurations:

Dev: a single in-memory Vault server for testing Vault
Standalone (default): a single Vault server persisting to a volume using the file storage backend
High-Availability (HA): a cluster of Vault servers that use an HA storage backend such as Consul (default)
External: a Vault Agent Injector server that depends on an external Vault server


# Deploy Vault in HA and Vault Auto Unseal
Before we jump into deploying Vault, it is important to understand what happens when we deploy a Vault pod. After deployment, the Vault pods start in a sealed state. That means until we unseal the Vault server, almost no operations are allowed. Here, unsealing is the process of decrypting the data inside Vault and allowing other services to access it.

# Test HashiCorp Vault
Vault starts in a sealed state, and that’s why all the Vault pods are in running status but none of the Vault pods are “ready”. To unseal Vault, we need to initialize it. Just exec into pod vault-0 and initialize your Vault instance (and keep your generated keys safe) as shown below:
````
$ kubectl exec -it vault-0 vault operator init

Recovery Key 1: ZtVe+JEjkLujUoUZYDUI8JPLBqPV6YVciZPyeEZ0/4xK
Recovery Key 2: 96vSOcPGUovI0cZK+D5x9Omab2hmeC2Pyv/8+iyfJoaJ
Recovery Key 3: eXjSDJlQh2BScDJtToH3iBTepVKrsh4+uFB1DqkWYl3C
Recovery Key 4: 4BHyg3K6DpdSS2EdkLkU4UlfFVOR1z68L/Q2P3h2ykrA
Recovery Key 5: jpmow1/POQkFwrMIqco6BtfNWw56g35qGXJkY1AuqUIk

Initial Root Token: hvs.tyWreuLnIrvhuDDta5akk0c7

Success! Vault is initialized

Recovery key initialized with 5 key shares and a key threshold of 3. Please
securely distribute the key shares printed above.
````

Now, we see the Vault unsealer in action:

```
$ kubectl get pods -n vault
NAME                                           READY   STATUS    RESTARTS
vault-0                                        1/1     Running   0      
vault-1                                        1/1     Running   0     
vault-2                                        1/1     Running   0         
```

# Vault from the command line
Next, we’ll need to exec into the Pod running Vault in order to configure it and add our secrets, like so:
```
kubectl exec -it vault-0 -- /bin/sh
```

With an active terminal session in the Vault pod, we’ll first need to enable Vault’s Key Value v2 Secrets Engine, which will allow us to create and store a simple key-value secret, like so:

```
vault secrets enable -path=internal kv-v2
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
```
Next, we’ll need to enable Vault’s built-in K8s auth, so that it will be able to authenticate with Vault using a Kubernetes Service Account Token that we can get from our running cluster, like so:

```
vault auth enable kubernetes
```
Then we’ll need to add the K8s host IP to the Vault auth config:

```
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

Next, we’ll need to create a Vault policy called internal-app that will allow read access to our defined path within Vault:

```
vault policy write internal-app - <<EOF
path "internal/data/database/config" {
capabilities = ["read"]
}
EOF
```
Then create a Vault role that includes references to the Vault role we just created, the K8s service account we’ll create in the next step, and the K8s namespace it will have access to within our Kubernetes cluster, like so:

```
vault write auth/kubernetes/role/internal-app \
  bound_service_account_names=internal-app \
  bound_service_account_namespaces=default \
  policies=internal-app \
  ttl=24h

```

# Using the Agent Injector to make our life easier
Next, we’ll look at an automated way to do essentially the same thing. This time, instead of manually defining a ConfigMap and an init container, we’ll have the Vault Agent Injector create those for us.

As shown below, when we deploy our app, the Vault Agent Injector (which we also deployed with Helm above) will augment our deployment with the additional K8s resources required for authenticating to Vault, getting the secret, and writing it to local storage.

The Vault Agent Injector will determine what secrets it needs to add, and where to write them, according to the Vault annotations included in the resource definition, as shown below.

```
kubectl apply -f deployment.yaml
```

# Conclusion
Vault can be used to securely inject secrets like database credentials into running Pods in Kubernetes so that your application can access them. Above, we looked at two ways to do this – manually and in an automated fashion. In both cases, an init container spins up a Vault Agent that authenticates with Vault, gets the secrets, and writes them to a local storage volume that your application can access during runtime.