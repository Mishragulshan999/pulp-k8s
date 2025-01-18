# Pulp

[Pulp](https://pulpproject.org/) is a platform for managing repositories of content, such as software packages, and making them available to a large number of consumers.

With Pulp you can:

* Locally mirror all or part of a repository
* Host your own content in a new repository
* Manage content from multiple sources in one place
* Promote content through different repos in an organized way

If you have dozens, hundreds, or thousands of software packages and need a better way to manage them, Pulp can help.

Pulp is completely free and open-source!

* License: GPLv2+
* Documentation: [https://docs.pulpproject.org/](https://docs.pulpproject.org/)
* Source: [https://github.com/pulp/pulpcore/](https://github.com/pulp/pulpcore/)

For more information, check out the project website: [https://pulpproject.org](https://pulpproject.org)

If you want to evaluate Pulp quickly, try [Pulp in One Container](https://pulpproject.org/pulp-in-one-container/)

## Pulp Operator

See our documentation on [Pulp Operator page](https://docs.pulpproject.org/pulp_operator/).

Pulp Operator is in beta stage and under active development, with the goal to provide a scalable and robust cluster for Pulp 3.
If you find any problem, please check our [issue page](https://github.com/pulp/pulp-operator/issues?q=is%3Aissue+is%3Aopen+label%3Ago-alpha) with the current known issues or feel free to fill a new bug or rfe in case it is not addressed yet.

Note that Pulp operator works with three different types of service containers (the operator itself, the main service and the web service):


## Deploying PostgreSQL

```
kubectl create ns db
kubectl apply -f standard-sc.yaml
kubectl apply -f https://raw.githubusercontent.com/pulp/pulp-operator/main/config/samples/external_db.yaml
```

## Installing Pulp Operator Using Helm Chart 

```
kubectl create ns pulp
kubectl config set-context --current --namespace pulp
helm repo add pulp-operator https://github.com/pulp/pulp-k8s-resources/raw/main/helm-charts/ --force-update
helm install pulp pulp-operator/pulp-operator
```

### Verify the operator 

```
kubectl get pod -n pulp
```


## Deploy Pulp CR (Custom Resource):

```
kubectl apply -f external-db-secret.yaml
kubectl apply -f pulp-sample.yaml
```
### Verify the pulp container is running or not 

```
kubectl get pod -n pulp
```

### Retrieve the PULP admin Password

```
kubectl get secret pulp-admin-password -o jsonpath="{.data.password}" | base64 --decode
Output:- XXXXX
```
### 1. Create a Remote in Pulp

```
curl -u admin:XXXXXXXX -X POST http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/remotes/container/container/ \
-H "Content-Type: application/json" \
-d '{
  "name": "docker-hub-test",
  "url": "https://registry.hub.docker.com",
  "upstream_name": "library/nginx",
  "policy": "on_demand",
  "pulp_labels": {"source": "docker-hub"}
}'
```

### 2. Create a Repository in Pulp

```
curl -u admin:XXXXXXX -X POST http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/repositories/container/container/ \
-H "Content-Type: application/json" \
-d '{
  "name": "docker-hub-test"
}'
```

###  3. Sync the Remote with the Repository

```
curl -u admin:XXXXXX -X POST http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/repositories/container/container/01925816-4bf8-73ad-b0f4-351f796dd94e/sync/ \
-H "Content-Type: application/json" \
-d '{
  "remote": "/pulp/api/v3/remotes/container/container/01925815-7b2c-783e-8e1f-8f7afe6cfcbc/"
}'
```
### Login the pulp repo

```
sudo docker login -u admin -p password pulp-dc307.dev.app.intacct.com
```

```
pulp repo: http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/repositories/
```
```
Pulp UI links: 
http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/repositories/
http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/artifacts/
http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/remotes/
http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/content/
http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/distributions/
http://pulp-dc307.dev.app.intacct.com/pulp/api/v3/tasks/
```

