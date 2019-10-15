# Clean-up

![Clean-up](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/cleanup.svg?sanitize=true
"Clean-up")

Uninstall Jenkins X:

```bash
jx uninstall --context="${USER}-jx-k8s.mylabs.dev"
```

Remove `front-end` repository in GitHub:

```bash
jx delete repo --github --org "ruzickap" --name="front-end" --batch-mode="true"
jx delete repo --github --org "ruzickap" --name="environment-mylabs-production" --batch-mode="true"
jx delete repo --github --org "ruzickap" --name="environment-mylabs-staging" --batch-mode="true"
```

Delete k8s cluster in AWS:

```bash
kops delete cluster --state s3://${USER}-kops-state-jenkinsx ${USER}-jx-k8s.mylabs.dev --yes
```

Delete S3 bucket:

```bash
aws s3api delete-bucket --bucket ${USER}-kops-state-jenkinsx --region eu-central-1
```

Delete default `jx` directory:

```bash
rm -rf ~/.jx
```

Remove `tmp` directory:

```bash
rm -rf tmp
```

Remove other files:

```bash
rm demo-magic.sh README.sh &> /dev/null
```

Remove default `kubeconfig`:

```bash
rm ~/.kube/config
```
