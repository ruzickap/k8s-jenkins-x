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

Authorize to AWS using AWS CLI: [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

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
  --git-api-token="$GITHUB_TOKEN" \
  --git-provider-url="https://github.com" \
  --git-username="ruzickap" \
  --kaniko=true \
  --lts-bucket=${USER}-jx-k8s.mylabs.dev \
  --master-size=t3.small \
  --node-size=t3.medium \
  --nodes=3 \
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
running command: kops create cluster --name pruzicka-jx-k8s.mylabs.dev --node-count 3 --node-size t3.medium --master-size t3.small --cloud-labels Owner=pruzicka,Environment=Test,Division=Services --authorization RBAC --zones eu-central-1a --yes --state s3://pruzicka-kops-state-jenkinsx
I1017 17:21:28.448971   16551 create_cluster.go:519] Inferred --cloud=aws from zone "eu-central-1a"
I1017 17:21:28.547392   16551 subnets.go:184] Assigned CIDR 172.20.32.0/19 to subnet eu-central-1a
I1017 17:21:29.372569   16551 create_cluster.go:1486] Using SSH public key: /home/pruzicka/.ssh/id_rsa.pub
I1017 17:21:31.321476   16551 executor.go:103] Tasks: 0 done / 85 total; 43 can run
I1017 17:21:31.891533   16551 vfs_castore.go:729] Issuing new certificate: "etcd-manager-ca-main"
I1017 17:21:31.984557   16551 vfs_castore.go:729] Issuing new certificate: "apiserver-aggregator-ca"
I1017 17:21:31.997063   16551 vfs_castore.go:729] Issuing new certificate: "etcd-clients-ca"
I1017 17:21:32.055963   16551 vfs_castore.go:729] Issuing new certificate: "ca"
I1017 17:21:32.247736   16551 vfs_castore.go:729] Issuing new certificate: "etcd-peers-ca-main"
I1017 17:21:32.250741   16551 vfs_castore.go:729] Issuing new certificate: "etcd-manager-ca-events"
I1017 17:21:32.288763   16551 vfs_castore.go:729] Issuing new certificate: "etcd-peers-ca-events"
I1017 17:21:33.010316   16551 executor.go:103] Tasks: 43 done / 85 total; 24 can run
I1017 17:21:33.612811   16551 vfs_castore.go:729] Issuing new certificate: "kubelet-api"
I1017 17:21:33.716839   16551 vfs_castore.go:729] Issuing new certificate: "apiserver-proxy-client"
I1017 17:21:33.769650   16551 vfs_castore.go:729] Issuing new certificate: "kube-scheduler"
I1017 17:21:33.785984   16551 vfs_castore.go:729] Issuing new certificate: "kube-proxy"
I1017 17:21:33.882883   16551 vfs_castore.go:729] Issuing new certificate: "kube-controller-manager"
I1017 17:21:34.021580   16551 vfs_castore.go:729] Issuing new certificate: "apiserver-aggregator"
I1017 17:21:34.021657   16551 vfs_castore.go:729] Issuing new certificate: "kubelet"
I1017 17:21:34.042589   16551 vfs_castore.go:729] Issuing new certificate: "kubecfg"
I1017 17:21:34.081027   16551 vfs_castore.go:729] Issuing new certificate: "kops"
I1017 17:21:34.123360   16551 vfs_castore.go:729] Issuing new certificate: "master"
I1017 17:21:34.334705   16551 executor.go:103] Tasks: 67 done / 85 total; 16 can run
I1017 17:21:34.559352   16551 launchconfiguration.go:364] waiting for IAM instance profile "nodes.pruzicka-jx-k8s.mylabs.dev" to be ready
I1017 17:21:34.586373   16551 launchconfiguration.go:364] waiting for IAM instance profile "masters.pruzicka-jx-k8s.mylabs.dev" to be ready
I1017 17:21:44.941708   16551 executor.go:103] Tasks: 83 done / 85 total; 2 can run
I1017 17:21:45.453092   16551 executor.go:103] Tasks: 85 done / 85 total; 0 can run
I1017 17:21:45.453203   16551 dns.go:155] Pre-creating DNS records
I1017 17:21:46.329503   16551 update_cluster.go:294] Exporting kubecfg for cluster
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
Loaded Cluster JSON: {"kind":"Cluster","apiVersion":"kops/v1alpha2","metadata":{"name":"pruzicka-jx-k8s.mylabs.dev","creationTimestamp":"2019-10-17T15:21:29Z"},"spec":{"channel":"stable","configBase":"s3://pruzicka-kops-state-jenkinsx/pruzicka-jx-k8s.mylabs.dev","cloudProvider":"aws","kubernetesVersion":"1.14.6","subnets":[{"name":"eu-central-1a","zone":"eu-central-1a","cidr":"172.20.32.0/19","type":"Public"}],"masterPublicName":"api.pruzicka-jx-k8s.mylabs.dev","networkCIDR":"172.20.0.0/16","topology":{"masters":"public","nodes":"public","dns":{"type":"Public"}},"nonMasqueradeCIDR":"100.64.0.0/10","sshAccess":["0.0.0.0/0"],"kubernetesApiAccess":["0.0.0.0/0"],"etcdClusters":[{"name":"main","etcdMembers":[{"name":"a","instanceGroup":"master-eu-central-1a"}],"memoryRequest":"100Mi","cpuRequest":"200m"},{"name":"events","etcdMembers":[{"name":"a","instanceGroup":"master-eu-central-1a"}],"memoryRequest":"100Mi","cpuRequest":"100m"}],"kubelet":{"anonymousAuth":false},"networking":{"kubenet":{}},"api":{"dns":{}},"authorization":{"rbac":{}},"cloudLabels":{"Division":"Services","Environment":"Test","Owner":"pruzicka"},"iam":{"legacy":false,"allowContainerRegistry":true}}}
new json: {"apiVersion":"kops/v1alpha2","kind":"Cluster","metadata":{"creationTimestamp":"2019-10-17T15:21:29Z","name":"pruzicka-jx-k8s.mylabs.dev"},"spec":{"additionalPolicies":{"node":"[\n      {\n        \"Effect\": \"Allow\",\n        \"Action\": [\"ecr:InitiateLayerUpload\", \"ecr:UploadLayerPart\",\"ecr:CompleteLayerUpload\",\"ecr:PutImage\"],\n        \"Resource\": [\"*\"]\n      }\n    ]"},"api":{"dns":{}},"authorization":{"rbac":{}},"channel":"stable","cloudLabels":{"Division":"Services","Environment":"Test","Owner":"pruzicka"},"cloudProvider":"aws","configBase":"s3://pruzicka-kops-state-jenkinsx/pruzicka-jx-k8s.mylabs.dev","docker":{"insecureRegistry":"100.64.0.0/10"},"etcdClusters":[{"cpuRequest":"200m","etcdMembers":[{"instanceGroup":"master-eu-central-1a","name":"a"}],"memoryRequest":"100Mi","name":"main"},{"cpuRequest":"100m","etcdMembers":[{"instanceGroup":"master-eu-central-1a","name":"a"}],"memoryRequest":"100Mi","name":"events"}],"iam":{"allowContainerRegistry":true,"legacy":false},"kubelet":{"anonymousAuth":false},"kubernetesApiAccess":["0.0.0.0/0"],"kubernetesVersion":"1.14.6","masterPublicName":"api.pruzicka-jx-k8s.mylabs.dev","networkCIDR":"172.20.0.0/16","networking":{"kubenet":{}},"nonMasqueradeCIDR":"100.64.0.0/10","sshAccess":["0.0.0.0/0"],"subnets":[{"cidr":"172.20.32.0/19","name":"eu-central-1a","type":"Public","zone":"eu-central-1a"}],"topology":{"dns":{"type":"Public"},"masters":"public","nodes":"public"}}}
Updating Cluster configuration to enable insecure Docker registries 100.64.0.0/10
running command: kops replace -f /tmp/kops-ig-json-177327770 --state s3://pruzicka-kops-state-jenkinsx
Updating the cluster
running command: kops update cluster --yes --state s3://pruzicka-kops-state-jenkinsx
Using cluster from kubectl context: pruzicka-jx-k8s.mylabs.dev

I1017 17:21:55.983274   16600 executor.go:103] Tasks: 0 done / 85 total; 43 can run
I1017 17:21:56.505035   16600 executor.go:103] Tasks: 43 done / 85 total; 24 can run
I1017 17:21:56.980158   16600 executor.go:103] Tasks: 67 done / 85 total; 16 can run
I1017 17:21:57.701292   16600 executor.go:103] Tasks: 83 done / 85 total; 2 can run
I1017 17:21:57.947370   16600 executor.go:103] Tasks: 85 done / 85 total; 0 can run
I1017 17:21:57.947448   16600 dns.go:155] Pre-creating DNS records
I1017 17:21:58.332514   16600 update_cluster.go:294] Exporting kubecfg for cluster
kops has set your kubectl context to pruzicka-jx-k8s.mylabs.dev

Cluster changes have been applied to the cloud.


Changes may require instances to restart: kops rolling-update cluster

Rolling update the cluster
running command: kops rolling-update cluster --cloudonly --yes --state s3://pruzicka-kops-state-jenkinsx
Using cluster from kubectl context: pruzicka-jx-k8s.mylabs.dev

NAME                    STATUS          NEEDUPDATE      READY   MIN     MAX
master-eu-central-1a    NeedsUpdate     1               0       1       1
nodes                   NeedsUpdate     3               0       3       3
W1017 17:21:59.568219   16640 instancegroups.go:160] Not draining cluster nodes as 'cloudonly' flag is set.
I1017 17:21:59.568277   16640 instancegroups.go:305] Stopping instance "i-09aeae26e862ccecf", in group "master-eu-central-1a.masters.pruzicka-jx-k8s.mylabs.dev" (this may take a while).
E1017 17:21:59.724738   16640 instancegroups.go:193] error deleting instance "i-09aeae26e862ccecf", node "": error deleting instance "i-09aeae26e862ccecf": error deleting instance "i-09aeae26e862ccecf": ScalingActivityInProgress: Activity 91c5b769-3e22-2c98-fdfd-8386a761f7c4 is in progress.
        status code: 400, request id: dcebdb93-f0f1-11e9-bc6b-b5635534ce36

master not healthy after update, stopping rolling-update: "error deleting instance \"i-09aeae26e862ccecf\": error deleting instance \"i-09aeae26e862ccecf\": ScalingActivityInProgress: Activity 91c5b769-3e22-2c98-fdfd-8386a761f7c4 is in progress.\n\tstatus code: 400, request id: dcebdb93-f0f1-11e9-bc6b-b5635534ce36"
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
Using helm values file: /tmp/ing-values-187813169
Deleting and cloning the Jenkins X versions repo
Cloning the Jenkins X versions repo https://github.com/jenkins-x/jenkins-x-versions.git with ref refs/heads/master to /home/pruzicka/.jx/jenkins-x-versions

Waiting for external loadbalancer to be created and update the nginx-ingress-controller service in kube-system namespace
External loadbalancer created

Waiting to find the external host name of the ingress controller Service in namespace kube-system with name jxing-nginx-ingress-controller
About to insert/update DNS CNAME record into HostedZone /hostedzone/ZY5AEYFXDBT4P with wildcard *.mylabs.dev pointing to abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com
Updated HostZone ID /hostedzone/ZY5AEYFXDBT4P successfully
nginx ingress controller installed and configured
? Configured to use long term logs storage: No
Set up a Git username and API token to be able to perform CI/CD
Select the CI/CD pipelines Git server and user
Setting the pipelines Git server https://github.com and user name ruzickap.
Cloning the Jenkins X cloud environments repo to /home/pruzicka/.jx/cloud-environments
Enumerating objects: 1440, done.
Total 1440 (delta 0), reused 0 (delta 0), pack-reused 1440
we are assuming your IAM roles are setup so that Kaniko can push images to your docker registry
Setting up prow config into namespace jx
Installing tekton into namespace jx

Installing Prow into namespace jx
with values file /home/pruzicka/.jx/cloud-environments/env-aws/myvalues.yaml

Installing jx into namespace jx
Installing jenkins-x-platform version: 2.0.1476


WARNING: waiting for install to be ready, if this is the first time then it will take a while to download images
Jenkins X deployments ready in namespace jx
Configuring the TeamSettings for ImportMode YAML
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
pod/crier-7c58ff4897-zm8xb                         1/1     Running     0          3m11s
pod/deck-b5b568797-4mnk4                           1/1     Running     0          3m11s
pod/deck-b5b568797-cn6kp                           1/1     Running     0          3m11s
pod/hook-6596bbffb9-csps9                          1/1     Running     0          3m10s
pod/hook-6596bbffb9-dhp97                          1/1     Running     0          3m10s
pod/horologium-749f6fb97b-h7lnx                    1/1     Running     0          3m10s
pod/jenkins-x-chartmuseum-d87cbb789-chbmw          1/1     Running     0          3m6s
pod/jenkins-x-controllerbuild-79bfc84b6c-gtd82     1/1     Running     0          3m4s
pod/jenkins-x-controllerrole-5ddcc565bc-6c8s7      1/1     Running     0          3m3s
pod/jenkins-x-docker-registry-69d666d455-sjq29     1/1     Running     0          3m4s
pod/jenkins-x-gcactivities-1571326200-kcbvq        0/1     Completed   0          108s
pod/jenkins-x-gcpods-1571326200-b8gsz              0/1     Completed   0          108s
pod/jenkins-x-heapster-5b7df679f6-rlnwk            2/2     Running     0          78s
pod/jenkins-x-nexus-6bc788447f-lgl78               1/1     Running     0          3m3s
pod/pipeline-67d685f957-s6qtq                      1/1     Running     0          3m11s
pod/pipelinerunner-64c59f6955-bvndw                1/1     Running     0          3m10s
pod/plank-9857d5b64-9q772                          1/1     Running     0          3m10s
pod/sinker-54bdd4fd45-hn6sq                        1/1     Running     0          3m10s
pod/tekton-pipelines-controller-786b485fc5-22crp   1/1     Running     0          3m18s
pod/tekton-pipelines-webhook-56cd88ddb5-4qszx      1/1     Running     0          3m18s
pod/tide-7ccc78d964-9sz58                          1/1     Running     0          3m10s

NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/deck                          ClusterIP   100.71.61.115    <none>        80/TCP     3m11s
service/heapster                      ClusterIP   100.69.151.211   <none>        8082/TCP   3m3s
service/hook                          ClusterIP   100.67.39.57     <none>        80/TCP     3m11s
service/jenkins-x-chartmuseum         ClusterIP   100.71.138.207   <none>        8080/TCP   3m5s
service/jenkins-x-docker-registry     ClusterIP   100.70.162.95    <none>        5000/TCP   3m4s
service/nexus                         ClusterIP   100.67.123.35    <none>        80/TCP     3m3s
service/pipelinerunner                ClusterIP   100.69.141.214   <none>        80/TCP     3m10s
service/tekton-pipelines-controller   ClusterIP   100.68.10.229    <none>        9090/TCP   3m19s
service/tekton-pipelines-webhook      ClusterIP   100.69.85.27     <none>        443/TCP    3m19s
service/tide                          ClusterIP   100.68.57.205    <none>        80/TCP     3m10s

NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/crier                         1/1     1            1           3m12s
deployment.apps/deck                          2/2     2            2           3m11s
deployment.apps/hook                          2/2     2            2           3m11s
deployment.apps/horologium                    1/1     1            1           3m11s
deployment.apps/jenkins-x-chartmuseum         1/1     1            1           3m6s
deployment.apps/jenkins-x-controllerbuild     1/1     1            1           3m5s
deployment.apps/jenkins-x-controllerrole      1/1     1            1           3m4s
deployment.apps/jenkins-x-docker-registry     1/1     1            1           3m4s
deployment.apps/jenkins-x-heapster            1/1     1            1           3m3s
deployment.apps/jenkins-x-nexus               1/1     1            1           3m3s
deployment.apps/pipeline                      1/1     1            1           3m11s
deployment.apps/pipelinerunner                1/1     1            1           3m11s
deployment.apps/plank                         1/1     1            1           3m10s
deployment.apps/sinker                        1/1     1            1           3m10s
deployment.apps/tekton-pipelines-controller   1/1     1            1           3m18s
deployment.apps/tekton-pipelines-webhook      1/1     1            1           3m18s
deployment.apps/tide                          1/1     1            1           3m10s

NAME                                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/crier-7c58ff4897                         1         1         1       3m12s
replicaset.apps/deck-b5b568797                           2         2         2       3m11s
replicaset.apps/hook-6596bbffb9                          2         2         2       3m11s
replicaset.apps/horologium-749f6fb97b                    1         1         1       3m11s
replicaset.apps/jenkins-x-chartmuseum-d87cbb789          1         1         1       3m6s
replicaset.apps/jenkins-x-controllerbuild-79bfc84b6c     1         1         1       3m5s
replicaset.apps/jenkins-x-controllerrole-5ddcc565bc      1         1         1       3m4s
replicaset.apps/jenkins-x-docker-registry-69d666d455     1         1         1       3m4s
replicaset.apps/jenkins-x-heapster-5b7df679f6            1         1         1       78s
replicaset.apps/jenkins-x-heapster-6457df4bd8            0         0         0       3m3s
replicaset.apps/jenkins-x-nexus-6bc788447f               1         1         1       3m3s
replicaset.apps/pipeline-67d685f957                      1         1         1       3m11s
replicaset.apps/pipelinerunner-64c59f6955                1         1         1       3m11s
replicaset.apps/plank-9857d5b64                          1         1         1       3m10s
replicaset.apps/sinker-54bdd4fd45                        1         1         1       3m10s
replicaset.apps/tekton-pipelines-controller-786b485fc5   1         1         1       3m18s
replicaset.apps/tekton-pipelines-webhook-56cd88ddb5      1         1         1       3m18s
replicaset.apps/tide-7ccc78d964                          1         1         1       3m10s

NAME                                          COMPLETIONS   DURATION   AGE
job.batch/jenkins-x-gcactivities-1571326200   1/1           58s        108s
job.batch/jenkins-x-gcpods-1571326200         1/1           59s        108s

NAME                                   SCHEDULE         SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/jenkins-x-gcactivities   0/30 */3 * * *   False     0        108s            3m4s
cronjob.batch/jenkins-x-gcpods         0/30 */3 * * *   False     0        108s            3m4s
cronjob.batch/jenkins-x-gcpreviews     0 */3 * * *      False     0        <none>          3m3s
```

Look at the `ingress` and `endpoints`:

```bash
kubectl get ingress,endpoints
```

Output:

```text
NAME                                 HOSTS                           ADDRESS                                                                            PORTS   AGE
ingress.extensions/chartmuseum       chartmuseum.jx.mylabs.dev       abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com   80      2m57s
ingress.extensions/deck              deck.jx.mylabs.dev              abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com   80      2m57s
ingress.extensions/docker-registry   docker-registry.jx.mylabs.dev   abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com   80      2m56s
ingress.extensions/hook              hook.jx.mylabs.dev              abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com   80      2m56s
ingress.extensions/nexus             nexus.jx.mylabs.dev             abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com   80      2m56s
ingress.extensions/tide              tide.jx.mylabs.dev              abb6dc8b3f0f211e9b6c6029d77b9317-f6354a2b37f1f6d2.elb.eu-central-1.amazonaws.com   80      2m57s

NAME                                    ENDPOINTS                         AGE
endpoints/deck                          100.96.1.4:8080,100.96.3.4:8080   3m11s
endpoints/heapster                      100.96.3.10:8082                  3m3s
endpoints/hook                          100.96.1.8:8888,100.96.3.7:8888   3m11s
endpoints/jenkins-x-chartmuseum         100.96.3.8:8080                   3m5s
endpoints/jenkins-x-docker-registry     100.96.1.10:5000                  3m4s
endpoints/nexus                         100.96.2.10:8081                  3m3s
endpoints/pipelinerunner                100.96.2.5:8080                   3m10s
endpoints/tekton-pipelines-controller   100.96.3.3:9090                   3m19s
endpoints/tekton-pipelines-webhook      100.96.2.4:8443                   3m19s
endpoints/tide                          100.96.2.6:8888                   3m10s
```

You can also use `jx get environments` to get the environments:

```bash
kubectl get environments -n jx
```

Output:

```text
NAME         NAMESPACE       KIND          PROMOTION   ORDER   GIT URL                                                         GIT BRANCH
dev          jx              Development   Never
production   jx-production   Permanent     Manual      200     https://github.com/ruzickap/environment-mylabs-production.git
staging      jx-staging      Permanent     Auto        100     https://github.com/ruzickap/environment-mylabs-staging.git
```

Or you can use the `jx` command to see the environments:

```bash
jx get env
```

Output:

```text
NAME       LABEL       KIND        PROMOTE NAMESPACE     ORDER CLUSTER SOURCE                                                        REF PR
dev        Development Development Never   jx            0
staging    Staging     Permanent   Auto    jx-staging    100           https://github.com/ruzickap/environment-mylabs-staging.git
production Production  Permanent   Manual  jx-production 200           https://github.com/ruzickap/environment-mylabs-production.git
```

Install Tekton Dashboard to see the details of the builds:

```bash
curl -sL https://github.com/tektoncd/dashboard/releases/download/v0.2.0/release.yaml | sed "s/namespace: tekton-pipelines/namespace: jx/" | kubectl apply -f -
```

Output:

```text
serviceaccount/tekton-dashboard created
customresourcedefinition.apiextensions.k8s.io/extensions.dashboard.tekton.dev created
clusterrole.rbac.authorization.k8s.io/tekton-dashboard-minimal created
clusterrolebinding.rbac.authorization.k8s.io/tekton-dashboard-minimal created
deployment.apps/tekton-dashboard created
service/tekton-dashboard created
task.tekton.dev/pipeline0-task created
pipeline.tekton.dev/pipeline0 created
```

Create Ingress for Tekton Dashboard:

```bash
cat << EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tekton-dashboard
  namespace: jx
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/auth-secret: jx-basic-auth
    nginx.ingress.kubernetes.io/auth-type: basic
spec:
  rules:
    - host: tekton-dashboard.jx.mylabs.dev
      http:
        paths:
          - backend:
              serviceName: tekton-dashboard
              servicePort: 9097
            path: /
EOF
```

Output:

```text
ingress.extensions/tekton-dashboard created
```
