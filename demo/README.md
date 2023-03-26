# Install External Secrets using Helm:

```
helm repo add external-secrets https://charts.external-secrets.io/
```

```
helm repo update external-secrets
```

```
helm search repo external-secrets/external-secrets
```

```
helm upgrade --install external-secrets external-secrets/external-secrets --version 0.8.1 -n external-secrets --create-namespace
```

# Deploy demo  External Secrets to EKS clusters.
Create ServiceAccount with "IRSA" role.
```
 kubectl apply -f serviceaccount.yaml
```

The "ClusterSecretStore" is a cluster scoped SecretStore that can be referenced by all ExternalSecrets from all namespaces. Use it to offer a central gateway to your secret backend

Deploy "ClusterSecretStore" with AWS Secrets Manager Provider. 

```
 kubectl apply -f css-secrets-manager.yaml
```
Deploy "ClusterSecretStore" with AWS Parameter Store Provider. 
```
 kubectl apply -f css-parameter-store.yaml
```

Deploy "ExternalSecret" with AWS Parameter Store Provider. 
```
 kubectl apply -f external-secret.yaml
```

# Deploy mysql to the EKS cluster and get "MYSQL_ROOT_PASSWORD" from ExternalSecret.
```
 kubectl apply -f deployment.yaml
```