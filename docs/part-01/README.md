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
  --helm3=true \
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
```
