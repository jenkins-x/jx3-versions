# Upgrade of External Secrets Operator
We're upgrading the External Secrets Operator defined in jx3-versions from version 0.6.0 to 2.8.0 in preparation for
migrating JayeX to use ESO instead of Kubernetes External Secrets.

The existing ESO chart has been in jx3-version since 2022 but not fully supported and not maintained version-wise.
It is not being used by JayeX yet so this upgrade is only relevant to users who have used the jx3-versions ESO chart
to install ESO resources in their cluster. If you have not done this then you can ignore this upgrade.

If unsure whether you have ESO resources in your cluster, you can check with the following command:

```bash
kubectl get externalsecrets.external-secrets.io,secretstores.external-secrets.io,clusterexternalsecrets.external-secrets.io,clustersecretstores.external-secrets.io -A -o name 2>/dev/null | grep -q . \
    && echo "ESO resources found — follow the migration steps below" \
    || echo "No ESO resources found — safe to ignore this upgrade"
```

The upgrade is breaking as the ESO CRDs have upgraded from v1beta1 to v1 in this time.
Version 2.8.0 does not support v1beta1 any more so if you have existing ESO resources these will need to be converted to v1 before upgrading.

## Migrating existing ESO CRDs to v1

### 1. Upgrade ESO to the bridge version (0.16.2)
Bump ESO to 0.16.2 (the last version that serves both v1beta1 and v1).

### 2. Migrate existing ESO resources to v1
Update your manifests from `external-secrets.io/v1beta1` to `external-secrets.io/v1` in git.
According to the ESO maintainers there are no schema changes
— it's a pure apiVersion bump (see https://github.com/external-secrets/external-secrets/issues/4785).

### 3. Upgrade to 2.8.0
Once every ESO resource is on `external-secrets.io/v1` and the 0.16.2 rollout is healthy, bump ESO to 2.8.0.
