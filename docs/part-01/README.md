# Jenkins X installation to AWS

## Prepare the local working environment

::: tip
You can skip these steps if you have all the required software already
installed.
:::

Install necessary software:

```bash
if [ -x /usr/bin/apt ]; then
  apt update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq awscli curl gettext-base git jq openssh-client sudo wget > /dev/null
fi
```

Install [kubectl](https://github.com/kubernetes/kubectl) binary:

```bash
if [ ! -x /usr/local/bin/kubectl ]; then
  sudo curl -s -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  sudo chmod a+x /usr/local/bin/kubectl
fi
```

Install [kops](https://github.com/kubernetes/kops):

```bash
if [ ! -x /usr/local/bin/kops ]; then
  sudo curl -s -L "https://github.com/kubernetes/kops/releases/download/1.14.0-alpha.3/kops-linux-amd64" > /usr/local/bin/kops
  sudo chmod a+x /usr/local/bin/kops
fi
```

Install [hub](https://hub.github.com/):

```bash
if [ ! -x /usr/local/bin/hub ]; then
  curl -s -L https://github.com/github/hub/releases/download/v2.12.3/hub-linux-amd64-2.12.3.tgz | tar xzf - -C /tmp/
  sudo mv /tmp/hub-linux-amd64-2.12.3/bin/hub /usr/local/bin/
fi
```

Install [jx](https://github.com/jenkins-x/jx):

```bash
if [ ! -x /usr/local/bin/jx ]; then
  curl -s -L "https://github.com/jenkins-x/jx/releases/download/$(curl --silent https://api.github.com/repos/jenkins-x/jx/releases/latest | jq -r '.tag_name')/jx-linux-amd64.tar.gz" | tar xz "jx" -C /tmp/
  sudo mv jx /usr/local/bin/
fi
```

## Configure AWS

::: warning
These steps should be done only once
:::

Authorize to AWS using AWS CLI: [https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

```bash
aws configure
...
```

Create DNS zone:

```bash
aws route53 create-hosted-zone --name ${MY_DOMAIN} --caller-reference ${MY_DOMAIN}
```

Use your domain registrar to change the nameservers for your zone (for example
`mylabs.dev`) to use the Amazon Route 53 nameservers. Here is the way how you
can find out the the Route 53 nameservers:

```bash
aws route53 get-hosted-zone --id $(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text) --query "DelegationSet.NameServers"
```

## Install Jenkins X

Generate SSH keys if not exists:

```bash
test -f $HOME/.ssh/id_rsa || ( install -m 0700 -d $HOME/.ssh && ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N "" )
```

Create S3 bucket:

```bash
aws s3api create-bucket --bucket ${USER}-kops-state-jenkinsx --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
```

Output:

```text
{
    "Location": "http://pruzicka-kops-state-jenkinsx.s3.amazonaws.com/"
}
```

Create Kubernetes cluster in Amazon and install Jenkins X there:

```bash
jx create cluster aws \
  --cluster-name=${USER}-jx-k8s.mylabs.dev \
  --default-admin-password="admin123" \
  --default-environment-prefix="mylabs" \
  --domain="mylabs.dev" \
  --environment-git-owner="ruzickap" \
  --git-api-token="$GITHUB_API_TOKEN" \
  --git-provider-url="https://github.com" \
  --git-username="ruzickap" \
  --kaniko=true \
  --lts-bucket=${USER}-jx-k8s.mylabs.dev \
  --master-size=t3.small \
  --node-size=t3.medium \
  --nodes=2 \
  --prow=true \
  --region=eu-central-1 \
  --state=s3://${USER}-kops-state-jenkinsx \
  --tags="Owner=${USER},Environment=Test,Division=Services" \
  --tekton=true \
  --zones=eu-central-1a \
  --batch-mode=true
```

Output:

```text
Creating cluster...
running command: kops create cluster --name pruzicka-jx-k8s.mylabs.dev --node-count 2 --node-size t3.medium --master-size t3.small --cloud-labels Owner=pruzicka,Environment=Test,Division=Services --authorization RBAC --zones eu-central-1a --yes --state s3://pruzicka-kops-state-jenkinsx
I1011 15:49:33.576910   30238 create_cluster.go:519] Inferred --cloud=aws from zone "eu-central-1a"
I1011 15:49:33.683445   30238 subnets.go:184] Assigned CIDR 172.20.32.0/19 to subnet eu-central-1a
I1011 15:49:34.508908   30238 create_cluster.go:1486] Using SSH public key: /home/pruzicka/.ssh/id_rsa.pub
I1011 15:49:36.348685   30238 executor.go:103] Tasks: 0 done / 85 total; 43 can run
I1011 15:49:36.893204   30238 vfs_castore.go:729] Issuing new certificate: "ca"
I1011 15:49:36.924978   30238 vfs_castore.go:729] Issuing new certificate: "etcd-manager-ca-events"
I1011 15:49:36.930391   30238 vfs_castore.go:729] Issuing new certificate: "etcd-manager-ca-main"
I1011 15:49:36.971615   30238 vfs_castore.go:729] Issuing new certificate: "apiserver-aggregator-ca"
I1011 15:49:37.004990   30238 vfs_castore.go:729] Issuing new certificate: "etcd-peers-ca-main"
I1011 15:49:37.023063   30238 vfs_castore.go:729] Issuing new certificate: "etcd-peers-ca-events"
I1011 15:49:37.402045   30238 vfs_castore.go:729] Issuing new certificate: "etcd-clients-ca"
I1011 15:49:37.666332   30238 executor.go:103] Tasks: 43 done / 85 total; 24 can run
I1011 15:49:38.248994   30238 vfs_castore.go:729] Issuing new certificate: "kubelet"
I1011 15:49:38.266943   30238 vfs_castore.go:729] Issuing new certificate: "master"
I1011 15:49:38.270488   30238 vfs_castore.go:729] Issuing new certificate: "kube-controller-manager"
I1011 15:49:38.335124   30238 vfs_castore.go:729] Issuing new certificate: "kube-scheduler"
I1011 15:49:38.384470   30238 vfs_castore.go:729] Issuing new certificate: "kube-proxy"
I1011 15:49:38.386860   30238 vfs_castore.go:729] Issuing new certificate: "apiserver-aggregator"
I1011 15:49:38.467228   30238 vfs_castore.go:729] Issuing new certificate: "kubecfg"
I1011 15:49:38.472458   30238 vfs_castore.go:729] Issuing new certificate: "kops"
I1011 15:49:38.500806   30238 vfs_castore.go:729] Issuing new certificate: "kubelet-api"
I1011 15:49:38.574251   30238 vfs_castore.go:729] Issuing new certificate: "apiserver-proxy-client"
I1011 15:49:38.946626   30238 executor.go:103] Tasks: 67 done / 85 total; 16 can run
I1011 15:49:39.207247   30238 launchconfiguration.go:364] waiting for IAM instance profile "masters.pruzicka-jx-k8s.mylabs.dev" to be ready
I1011 15:49:39.229969   30238 launchconfiguration.go:364] waiting for IAM instance profile "nodes.pruzicka-jx-k8s.mylabs.dev" to be ready
I1011 15:49:49.568666   30238 executor.go:103] Tasks: 83 done / 85 total; 2 can run
I1011 15:49:50.170277   30238 executor.go:103] Tasks: 85 done / 85 total; 0 can run
I1011 15:49:50.170330   30238 dns.go:155] Pre-creating DNS records
I1011 15:49:51.031400   30238 update_cluster.go:294] Exporting kubecfg for cluster
kops has set your kubectl context to pruzicka-jx-k8s.mylabs.dev

Cluster is starting.  It should be ready in a few minutes.

Suggestions:
 * validate cluster: kops validate cluster
 * list nodes: kubectl get nodes --show-labels
 * ssh to the master: ssh -i ~/.ssh/id_rsa admin@api.pruzicka-jx-k8s.mylabs.dev
 * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/addons.md.


kops has created cluster pruzicka-jx-k8s.mylabs.dev it will take a minute or so to startup
You can check on the status in another terminal via the command: kops validate cluster
WARNING: Waiting for the Cluster configuration...
Loaded Cluster JSON: {"kind":"Cluster","apiVersion":"kops/v1alpha2","metadata":{"name":"pruzicka-jx-k8s.mylabs.dev","creationTimestamp":"2019-10-11T13:49:34Z"},"spec":{"channel":"stable","configBase":"s3://pruzicka-kops-state-jenkinsx/pruzicka-jx-k8s.mylabs.dev","cloudProvider":"aws","kubernetesVersion":"1.14.6","subnets":[{"name":"eu-central-1a","zone":"eu-central-1a","cidr":"172.20.32.0/19","type":"Public"}],"masterPublicName":"api.pruzicka-jx-k8s.mylabs.dev","networkCIDR":"172.20.0.0/16","topology":{"masters":"public","nodes":"public","dns":{"type":"Public"}},"nonMasqueradeCIDR":"100.64.0.0/10","sshAccess":["0.0.0.0/0"],"kubernetesApiAccess":["0.0.0.0/0"],"etcdClusters":[{"name":"main","etcdMembers":[{"name":"a","instanceGroup":"master-eu-central-1a"}],"memoryRequest":"100Mi","cpuRequest":"200m"},{"name":"events","etcdMembers":[{"name":"a","instanceGroup":"master-eu-central-1a"}],"memoryRequest":"100Mi","cpuRequest":"100m"}],"kubelet":{"anonymousAuth":false},"networking":{"kubenet":{}},"api":{"dns":{}},"authorization":{"rbac":{}},"cloudLabels":{"Division":"Services","Environment":"Test","Owner":"pruzicka"},"iam":{"legacy":false,"allowContainerRegistry":true}}}
new json: {"apiVersion":"kops/v1alpha2","kind":"Cluster","metadata":{"creationTimestamp":"2019-10-11T13:49:34Z","name":"pruzicka-jx-k8s.mylabs.dev"},"spec":{"additionalPolicies":{"node":"[\n      {\n        \"Effect\": \"Allow\",\n        \"Action\": [\"ecr:InitiateLayerUpload\", \"ecr:UploadLayerPart\",\"ecr:CompleteLayerUpload\",\"ecr:PutImage\"],\n        \"Resource\": [\"*\"]\n      }\n    ]"},"api":{"dns":{}},"authorization":{"rbac":{}},"channel":"stable","cloudLabels":{"Division":"Services","Environment":"Test","Owner":"pruzicka"},"cloudProvider":"aws","configBase":"s3://pruzicka-kops-state-jenkinsx/pruzicka-jx-k8s.mylabs.dev","docker":{"insecureRegistry":"100.64.0.0/10"},"etcdClusters":[{"cpuRequest":"200m","etcdMembers":[{"instanceGroup":"master-eu-central-1a","name":"a"}],"memoryRequest":"100Mi","name":"main"},{"cpuRequest":"100m","etcdMembers":[{"instanceGroup":"master-eu-central-1a","name":"a"}],"memoryRequest":"100Mi","name":"events"}],"iam":{"allowContainerRegistry":true,"legacy":false},"kubelet":{"anonymousAuth":false},"kubernetesApiAccess":["0.0.0.0/0"],"kubernetesVersion":"1.14.6","masterPublicName":"api.pruzicka-jx-k8s.mylabs.dev","networkCIDR":"172.20.0.0/16","networking":{"kubenet":{}},"nonMasqueradeCIDR":"100.64.0.0/10","sshAccess":["0.0.0.0/0"],"subnets":[{"cidr":"172.20.32.0/19","name":"eu-central-1a","type":"Public","zone":"eu-central-1a"}],"topology":{"dns":{"type":"Public"},"masters":"public","nodes":"public"}}}
Updating Cluster configuration to enable insecure Docker registries 100.64.0.0/10
running command: kops replace -f /tmp/kops-ig-json-163771558 --state s3://pruzicka-kops-state-jenkinsx
Updating the cluster
running command: kops update cluster --yes --state s3://pruzicka-kops-state-jenkinsx
Using cluster from kubectl context: pruzicka-jx-k8s.mylabs.dev

I1011 15:50:00.671832   30501 executor.go:103] Tasks: 0 done / 85 total; 43 can run
I1011 15:50:01.213974   30501 executor.go:103] Tasks: 43 done / 85 total; 24 can run
I1011 15:50:01.741050   30501 executor.go:103] Tasks: 67 done / 85 total; 16 can run
I1011 15:50:02.795190   30501 executor.go:103] Tasks: 83 done / 85 total; 2 can run
I1011 15:50:03.119250   30501 executor.go:103] Tasks: 85 done / 85 total; 0 can run
I1011 15:50:03.119338   30501 dns.go:155] Pre-creating DNS records
I1011 15:50:03.487860   30501 update_cluster.go:294] Exporting kubecfg for cluster
kops has set your kubectl context to pruzicka-jx-k8s.mylabs.dev

Cluster changes have been applied to the cloud.


Changes may require instances to restart: kops rolling-update cluster

Rolling update the cluster
running command: kops rolling-update cluster --cloudonly --yes --state s3://pruzicka-kops-state-jenkinsx
Using cluster from kubectl context: pruzicka-jx-k8s.mylabs.dev

NAME                    STATUS          NEEDUPDATE      READY   MIN     MAX
master-eu-central-1a    NeedsUpdate     1               0       1       1
nodes                   NeedsUpdate     2               0       2       2
W1011 15:50:04.662274   30524 instancegroups.go:160] Not draining cluster nodes as 'cloudonly' flag is set.
I1011 15:50:04.662289   30524 instancegroups.go:305] Stopping instance "i-0a6be1c1ee16e640e", in group "master-eu-central-1a.masters.pruzicka-jx-k8s.mylabs.dev" (this may take a while).
E1011 15:50:04.844655   30524 instancegroups.go:193] error deleting instance "i-0a6be1c1ee16e640e", node "": error deleting instance "i-0a6be1c1ee16e640e": error deleting instance "i-0a6be1c1ee16e640e": ScalingActivityInProgress: Activity 5ad5b6ec-54df-520c-c757-d994a7ef6d62 is in progress.
        status code: 400, request id: 074d558b-ec2e-11e9-9d29-2d964ef814ca

master not healthy after update, stopping rolling-update: "error deleting instance \"i-0a6be1c1ee16e640e\": error deleting instance \"i-0a6be1c1ee16e640e\": ScalingActivityInProgress: Activity 5ad5b6ec-54df-520c-c757-d994a7ef6d62 is in progress.\n\tstatus code: 400, request id: 074d558b-ec2e-11e9-9d29-2d964ef814ca"
ERROR: Error: Command failed  kops rolling-update cluster --cloudonly --yes --state s3://pruzicka-kops-state-jenkinsx
WARNING: Failed to perform rolling upgrade: exit status 1
Cluster configuration updated
Waiting for the Kubernetes cluster to be ready so we can continue...
WARNING: retrying after error: exit status 1
.


Waiting to for a valid kops cluster state...
WARNING: retrying after error: exit status 2
.

State of kops cluster: OK

Initialising cluster ...
Namespace jx created
Context "pruzicka-jx-k8s.mylabs.dev" modified.
Updating storageclass gp2 to be the default
Git configured for user: Petr Ruzicka and email petr.ruzicka@gmail.com
helm installed and configured
Using helm values file: /tmp/ing-values-292207053
WARNING: Manually switching namespace to for helm3 alpha - kube-system, this code should be removed once --namespaces is implemented
Waiting for external loadbalancer to be created and update the nginx-ingress-controller service in kube-system namespace
External loadbalancer created

Waiting to find the external host name of the ingress controller Service in namespace kube-system with name jxing-nginx-ingress-controller
About to insert/update DNS CNAME record into HostedZone /hostedzone/ZxxxxxxxxxxxP with wildcard *.mylabs.dev pointing to ae5416c4fec2e11e9a1d202b04ce9858-d1e6b6d4e25907f9.elb.eu-central-1.amazonaws.com
Updated HostZone ID /hostedzone/ZxxxxxxxxxxxP successfully
nginx ingress controller installed and configured
? Configured to use long term logs storage: No
Set up a Git username and API token to be able to perform CI/CD
Select the CI/CD pipelines Git server and user
Setting the pipelines Git server https://github.com and user name ruzickap.
Cloning the Jenkins X cloud environments repo to /home/pruzicka/.jx/cloud-environments
Cloning the Jenkins X cloud environments repo to /home/pruzicka/.jx/cloud-environments
Enumerating objects: 1440, done.
Total 1440 (delta 0), reused 0 (delta 0), pack-reused 1440
we are assuming your IAM roles are setup so that Kaniko can push images to your docker registry
Setting up prow config into namespace jx
Installing tekton into namespace jx
WARNING: Manually switching namespace to for helm3 alpha - jx, this code should be removed once --namespaces is implemented
Installing Prow into namespace jx
with values file /home/pruzicka/.jx/cloud-environments/env-aws/myvalues.yaml
WARNING: Manually switching namespace to for helm3 alpha - jx, this code should be removed once --namespaces is implemented
Installing jx into namespace jx
Installing jenkins-x-platform version: 2.0.1431
WARNING: Manually switching namespace to for helm3 alpha - jx, this code should be removed once --namespaces is implemented
WARNING: waiting for install to be ready, if this is the first time then it will take a while to download images
Jenkins X deployments ready in namespace jx
Configuring the TeamSettings for ImportMode YAML
Setting the helm binary name to: helm3
Creating default staging and production environments
Using Git provider GitHub at https://github.com
? Using Git user name: ruzickap
? Using organisation: ruzickap
Creating repository ruzickap/environment-mylabs-staging
Creating Git repository ruzickap/environment-mylabs-staging
Pushed Git repository to https://github.com/ruzickap/environment-mylabs-staging

Creating staging Environment in namespace jx
Created environment staging
Namespace jx-staging created
Creating GitHub webhook for ruzickap/environment-mylabs-staging for url http://hook.jx.mylabs.dev/hook
Using Git provider GitHub at https://github.com
? Using Git user name: ruzickap
? Using organisation: ruzickap
Creating repository ruzickap/environment-mylabs-production
Creating Git repository ruzickap/environment-mylabs-production
Pushed Git repository to https://github.com/ruzickap/environment-mylabs-production

Creating production Environment in namespace jx
Created environment production
Namespace jx-production created
Creating GitHub webhook for ruzickap/environment-mylabs-production for url http://hook.jx.mylabs.dev/hook

Jenkins X installation completed successfully


        ********************************************************

             NOTE: Your admin password is: admin123

        ********************************************************


Your Kubernetes context is now set to the namespace: jx
To switch back to your original namespace use: jx namespace default
Or to use this context/namespace in just one terminal use: jx shell
For help on switching contexts see: https://jenkins-x.io/developing/kube-context/
To import existing projects into Jenkins:       jx import
To create a new Spring Boot microservice:       jx create spring -d web -d actuator
To create a new microservice from a quickstart: jx create quickstart
```

You can see the production and staging repository created by Jenkins X
in GitHub:

* [https://github.com/ruzickap/environment-mylabs-production](https://github.com/ruzickap/environment-mylabs-production)

* [https://github.com/ruzickap/environment-mylabs-staging](https://github.com/ruzickap/environment-mylabs-staging)

![GitHub https://github.com/ruzickap/environment-mylabs-production repository](./jenkins-x-github.png
"GitHub https://github.com/ruzickap/environment-mylabs-production repository")

Few commands showing the Jenkins X installation inside Kubernetes:

```bash
kubectl get all -n jx
```

Output:

```text
NAME                                               READY   STATUS      RESTARTS   AGE
pod/crier-7c58ff4897-mk8bp                         1/1     Running     0          27m
pod/deck-b5b568797-bkn7b                           1/1     Running     0          27m
pod/deck-b5b568797-ck8n8                           1/1     Running     0          27m
pod/exposecontroller-4fslj                         0/1     Completed   0          27m
pod/hook-6596bbffb9-9h5pb                          1/1     Running     0          27m
pod/hook-6596bbffb9-zkcv8                          1/1     Running     0          27m
pod/horologium-749f6fb97b-6j8kr                    1/1     Running     0          27m
pod/jenkins-7bbb9cf8c7-krd82                       1/1     Running     0          27m
pod/jenkins-x-chartmuseum-d87cbb789-7hxrr          1/1     Running     0          27m
pod/jenkins-x-docker-registry-856b659fb5-4xhgc     1/1     Running     0          27m
pod/jenkins-x-heapster-6c8b894c48-24qk9            2/2     Running     0          25m
pod/jenkins-x-nexus-6bc788447f-p9lnt               1/1     Running     0          27m
pod/pipeline-67d685f957-9bbst                      1/1     Running     0          27m
pod/pipelinerunner-7d68ffcd7b-5cxsp                1/1     Running     0          27m
pod/plank-9857d5b64-ptdhr                          1/1     Running     0          27m
pod/sinker-54bdd4fd45-7qjnf                        1/1     Running     0          27m
pod/tekton-pipelines-controller-786b485fc5-ps82f   1/1     Running     0          27m
pod/tekton-pipelines-webhook-56cd88ddb5-59lnf      1/1     Running     0          27m
pod/tide-7ccc78d964-gcfxb                          1/1     Running     0          27m

NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
service/deck                          ClusterIP   100.69.126.250   <none>        80/TCP      27m
service/heapster                      ClusterIP   100.70.226.8     <none>        8082/TCP    27m
service/hook                          ClusterIP   100.68.176.214   <none>        80/TCP      27m
service/jenkins                       ClusterIP   100.69.139.188   <none>        8080/TCP    27m
service/jenkins-agent                 ClusterIP   100.66.253.26    <none>        50000/TCP   27m
service/jenkins-x-chartmuseum         ClusterIP   100.66.225.202   <none>        8080/TCP    27m
service/jenkins-x-docker-registry     ClusterIP   100.64.50.221    <none>        5000/TCP    27m
service/nexus                         ClusterIP   100.65.21.27     <none>        80/TCP      27m
service/pipelinerunner                ClusterIP   100.67.45.248    <none>        80/TCP      27m
service/tekton-pipelines-controller   ClusterIP   100.64.179.78    <none>        9090/TCP    27m
service/tekton-pipelines-webhook      ClusterIP   100.65.145.175   <none>        443/TCP     27m
service/tide                          ClusterIP   100.67.146.26    <none>        80/TCP      27m

NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/crier                         1/1     1            1           27m
deployment.apps/deck                          2/2     2            2           27m
deployment.apps/hook                          2/2     2            2           27m
deployment.apps/horologium                    1/1     1            1           27m
deployment.apps/jenkins                       1/1     1            1           27m
deployment.apps/jenkins-x-chartmuseum         1/1     1            1           27m
deployment.apps/jenkins-x-docker-registry     1/1     1            1           27m
deployment.apps/jenkins-x-heapster            1/1     1            1           27m
deployment.apps/jenkins-x-nexus               1/1     1            1           27m
deployment.apps/pipeline                      1/1     1            1           27m
deployment.apps/pipelinerunner                1/1     1            1           27m
deployment.apps/plank                         1/1     1            1           27m
deployment.apps/sinker                        1/1     1            1           27m
deployment.apps/tekton-pipelines-controller   1/1     1            1           27m
deployment.apps/tekton-pipelines-webhook      1/1     1            1           27m
deployment.apps/tide                          1/1     1            1           27m

NAME                                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/crier-7c58ff4897                         1         1         1       27m
replicaset.apps/deck-b5b568797                           2         2         2       27m
replicaset.apps/hook-6596bbffb9                          2         2         2       27m
replicaset.apps/horologium-749f6fb97b                    1         1         1       27m
replicaset.apps/jenkins-7bbb9cf8c7                       1         1         1       27m
replicaset.apps/jenkins-x-chartmuseum-d87cbb789          1         1         1       27m
replicaset.apps/jenkins-x-docker-registry-856b659fb5     1         1         1       27m
replicaset.apps/jenkins-x-heapster-6457df4bd8            0         0         0       27m
replicaset.apps/jenkins-x-heapster-6c8b894c48            1         1         1       25m
replicaset.apps/jenkins-x-nexus-6bc788447f               1         1         1       27m
replicaset.apps/pipeline-67d685f957                      1         1         1       27m
replicaset.apps/pipelinerunner-7d68ffcd7b                1         1         1       27m
replicaset.apps/plank-9857d5b64                          1         1         1       27m
replicaset.apps/sinker-54bdd4fd45                        1         1         1       27m
replicaset.apps/tekton-pipelines-controller-786b485fc5   1         1         1       27m
replicaset.apps/tekton-pipelines-webhook-56cd88ddb5      1         1         1       27m
replicaset.apps/tide-7ccc78d964                          1         1         1       27m

NAME                         COMPLETIONS   DURATION   AGE
job.batch/exposecontroller   1/1           14s        27m

NAME                                        LABEL   GIT URL                                                            GIT REF
buildpack.jenkins.io/classic-workloads              https://github.com/jenkins-x-buildpacks/jenkins-x-classic.git      master
buildpack.jenkins.io/kubernetes-workloads           https://github.com/jenkins-x-buildpacks/jenkins-x-kubernetes.git   master
```

You can also use `jx get environments` to get the environments:

```bash
kubectl get environments -n jx
```

```text
NAME         NAMESPACE       KIND          PROMOTION   ORDER   GIT URL                                                         GIT BRANCH
dev          jx              Development   Never
production   jx-production   Permanent     Manual      200     https://github.com/ruzickap/environment-mylabs-production.git
staging      jx-staging      Permanent     Auto        100     https://github.com/ruzickap/environment-mylabs-staging.git
```
