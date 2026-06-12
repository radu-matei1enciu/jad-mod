# JAD—Just Another Demonstrator

JAD is a demonstrator that deploys a fully-fledged dataspace as a Software-as-a-Service (SaaS) solution in Kubernetes.
This is to illustrate how Cloud Service Providers (CSPs) can deploy and manage dataspace components in their own cloud
infrastructure.

For that, JAD uses the "Virtual Connector" project: <https://github.com/eclipse-edc/Virtual-Connector>

## Components

Such a dataspace requires – at a minimum – the following components:

- a control plane: handles protocol messages and catalog data for each participant
- IdentityHub: responsible for managing Verifiable Credentials (presentation and storage)
- IssuerService: issues Verifiable Credentials to participants' IdentityHubs
- a data plane: performs the actual data transfer
- an identity provider: handles API authentication of management APIs. We are using Keycloak here.
- a vault: used to securely store sensitive data, such as the private keys etc. We are using Hashicorp Vault.
- a database server: contains persistent data of all the components. We are using PostgreSQL.
- a messaging system: used to process asynchronous messages. We are using NATS for this.
- a connector fabric manager (CFM): comprised of the `tenant-manager` and the `provision-manager` as well as several
  agents to manage dataspace participant resources

## Required tools and apps

- KinD: a basic Kubernetes runtime inside a single Docker container.
- Java 17+
- Docker
- `kubectl`
- Helm (for Traefik installation)
- macOS or Linux as an operating system. **Windows is not natively supported**!
- a POSIX-compliant shell (e.g., bash, zsh)
- [Bruno](https://www.usebruno.com) (or similar). The API requests here are optimized for Bruno, but other tools work as
  well. Bruno does offer a CLI client, but that does not handle token refresh automatically, so we'll use the GUI.

_All shell commands are executed from the root of the project unless stated otherwise._

## Getting started

### 1. Create a KinD cluster

To create a KinD cluster, run:

```shell
cp ~/.kube/config ~/.kube/config.bak # to save your existing kubeconfig
kind create cluster -n edcv --kubeconfig ~/.kube/edcv-kind.conf
ln -sf ~/.kube/edcv-kind.conf ~/.kube/config # to use KinD's kubeconfig
```

Next, we need to deploy a Gateway controller to allow access to services from outside the cluster. There are several
popular choices, and we've opted for [Traefik](https://doc.traefik.io/traefik/setup/kubernetes/) in this case. We could
have gone for Envoy, but Traefik is easier to set up and lighter-weight.

```shell
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install --namespace traefik traefik traefik/traefik --create-namespace -f values.yaml
```

Then, install the custom resource definitions (CRDs) for the Gateway API:

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
```

#### Enable network access to services

With the Gateway API, there are three main ways to access services from outside the cluster:

- using port-forwarding: this is a manual way to forward ports from the host to the cluster. This is not
  recommended for production use but works fine for local testing. We will use this approach here for simplicity.

- via a LoadBalancer service: this is typically used in cloud-hosted Kubernetes clusters, where the cloud provider
  provisions a load balancer automatically. This is the recommended approach for production use when running in
  cloud-hosted environments, and DNS names are used. For KinD, there is no built-in load balancer, but one can be
  installed

- via `NodePort` services: this exposes services on high-numbered ports on the host machine. This is not
  recommended for production use, and it gets complicated quickly when multiple services are involved, as is the case
  here. _This is not shown here_.

##### Option 1 (recommended): via port-forwarding

To set up port-forwarding, run the following command:

```shell
kubectl -n traefik port-forward svc/traefik 80
```

If you require higher priviliges use sudo:

```shell
sudo kubectl --kubeconfig=/home/radu/.kube/config -n traefik port-forward svc/traefik 80
```

This forwards port 80 from the host to the Traefik service inside the cluster. You may need to run this with `sudo`
privileges on some systems.

##### Option 2: via LoadBalancer (alternative)

The KinD project provides
a [cloud-like load balancer implementation](https://github.com/kubernetes-sigs/cloud-provider-kind). It emulates an
external LB as you would get on cloud-hosted K8s clusters.
Install it according to the instructions in the repository.

Verify, that the `EXTERNAL-IP` of the `traefik` service is not yet assigned:

```shell
kubectl get svc -n traefik
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
traefik   LoadBalancer   10.96.251.221   <pending>     80:31415/TCP,443:31650/TCP   22s
```

To assign an IP address to the Traefik LoadBalancer service, we need to run the external LB:

```shell
cloud-provider-kind
# on macOS:
sudo cloud-provider-kind
```

Now, if we rerun the previous command, we should see a similar output to this:

```shell
kubectl get svc -n traefik
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
traefik   LoadBalancer   10.96.251.221   172.18.0.3    80:31415/TCP,443:31650/TCP   2m31s
```

> Note that with the external LB, services inside the cluster must be accessed via the external IP address, e.g.
> `172.18.0.3` in this case. Variables inside the Bruno collection must be adjusted accordingly!

### 2. Deploy applications

#### 2.1 Option 1: Use pre-built images

There are pre-built images for all JAD apps available from [GHCR](https://github.com/Metaform/jad/packages) and the
Connector Fabric Manager images are available from
the [CFM GitHub Repository](https://github.com/eclipse-cfm/cfm/packages). Those are tested and we
strongly recommend using them.

#### 2.2 Option 2: Build images from source

However, for the adventurous among us who want to build them from source, for example, because they've modified the code
and now want to see it in action, please follow the following steps to build and load JAD apps:

- build Docker images:

  ```shell
  ./gradlew dockerize
  ```

  This will build the Docker images for all components and store them in the local Docker registry.

- load images into KinD: KinD has no access to the host's docker context, so we need to load the images into KinD. Note
  that other Kubernetes runtimes such as Minikube do things differently. Verify that all images are there by running
  `docker images`. Then run:

  ```shell
  kind load docker-image \
      ghcr.io/metaform/jad/controlplane:latest \
      ghcr.io/metaform/jad/identity-hub:latest \
      ghcr.io/metaform/jad/issuerservice:latest \
      ghcr.io/metaform/jad/dataplane:latest -n edcv
  ```

  or if you're a bash God:

  ```shell
  kind load docker-image -n edcv $(docker images --format "{{.Repository}}:{{.Tag}}" | grep '^ghcr.io/metaform/jad.*:latest')
  ```

- build CFM docker images locally:

  ```shell
  cd /path/to/cfm/
  make load-into-kind
  ```

  This builds all CFM components' docker images and loads them into your KinD cluster, assuming that your KinD cluster
  is named `"edcv"`. If not, set the cluster name for the make file accordingly:

  ```
  cd /path/to/cfm/
  make load-into-kind KIND_CLUSTER_NAME=your_cluster_name`.
  ```

  Note that individual `make` targets for all CFM components exist, for example `make load-into-kind-pmanager`.

- modify the deployment manifests of the components you want to load locally by setting the `imagePullPolicy: Never`
  which forces KinD to rely on local images rather than pulling them. This can be done with search-and-replace from your
  favorite editor, or you can do it from the command line by running

  ```shell
  sed -i "s/imagePullPolicy:.*Always/imagePullPolicy: Never/g" <FILENAME>
  ```

  **CAUTION Mac users**: this requires GNU-sed. By default, macOS, has a special version of `sed` so you will have
  to [install GNU sed first](https://medium.com/@bramblexu/install-gnu-sed-on-mac-os-and-set-it-as-default-7c17ef1b8f64)

- For the EDC-V components, the relevant files are `controlplane.yaml`, `dataplane.yaml`, `identityhub.yaml` and
  `issuerservice.yaml`
- as a simplification, and to modify the image pull policy of both EDC-V _and_ CFM components, run:

  ```shell
  grep -rlZ "imagePullPolicy: Always" k8s/apps  | xargs sed -i "s/imagePullPolicy:.*Always/imagePullPolicy: Never/g"
  ```

  For this, both the EDC-V and CFM docker images must be built locally!!

### 3. Deploy the services

JAD uses plain Kubernetes manifests to deploy the services. All the manifests are located in the [k8s](./k8s) folder.
While it is possible to just use the Kustomize plugin and running `kubectl apply -k k8s/`, you may experience nasty race
conditions because some services depend on others to be fully operational before they can start properly.

The recommended way is to deploy infrastructure services first, and application services second. This can be done
by running:

```shell
kubectl apply -k k8s/base/

# Wait for the infrastructure services to be ready:
kubectl wait --namespace edc-v \
            --for=condition=ready pod \
            --selector=type=edcv-infra \
            --timeout=90s

kubectl apply -k k8s/apps/

# Wait for seed jobs to be ready:
kubectl wait --namespace edc-v \
            --for=condition=complete job --all \
            --timeout=90s
```

Here's a copy-and-pasteable command to delete and redeploy everything:

```shell
kubectl delete -k k8s/; \
kubectl apply -k k8s/base && \
kubectl wait --namespace edc-v \
            --for=condition=ready pod \
            --selector=type=edcv-infra \
            --timeout=90s && \
kubectl apply -k k8s/apps && \
kubectl wait --namespace edc-v \
            --for=condition=complete job --all \
            --timeout=90s
```

_Note: the `";"` after `kubectl delete -k k8s/` is on purpose for robustness, to allow the command to fail if no
resources are deployed yet._

This deploys all the services in the correct order. The services are deployed in the `edc-v` namespace. Please verify
that everything got deployed correctly by running `kubectl get deployments -n edc-v`. This should output something like:

```text
NAME            READY   UP-TO-DATE   AVAILABLE             AGE
cfm-agents                1/1     1            1           117m
cfm-provision-manager     1/1     1            1           117m
cfm-tenant-manager        1/1     1            1           117m
controlplane              1/1     1            1           117m
dataplane                 1/1     1            1           117m
identityhub               1/1     1            1           117m
issuerservice             1/1     1            1           117m
keycloak                  1/1     1            1           110m
nats                      1/1     1            1           110m
postgres                  1/1     1            1           110m
vault                     1/1     1            1           110m
```

## Cleanup

To remove the deployment, run:

```shell
kubectl delete -k k8s/
```

## Troubleshooting

In case any errors occur referring to authentication or authorization, it is recommended to delete and re-deploy the
entire base and all apps.

For example, if a participant onboarding went only through half-way, we recommend to do a clean-slate redeployment.

In some cases, even deleting and re-creating the KinD cluster may be required.
