
The Cloud Credential Operator (CCO) Upgradable status for a cluster with manually maintained credentials is False by default.

    For minor releases, for example, from 4.12 to 4.13, this status prevents you from updating until you have addressed any updated permissions and annotated the CloudCredential resource to indicate that the permissions are updated as needed for the next version. This annotation changes the Upgradable status to True.

This helper script determines if the credential secrets in the cluster are still valid for the release you want to upgrade to.

**NB:** Requires you are logged into an OpenShift cluster as cluster-admin

- [Red Hat OpenShift 4.15 Documentation](https://docs.openshift.com/container-platform/4.15/updating/preparing_for_updates/preparing-manual-creds-update.html)


```bash
# Validate thath upgrading is blocked
oc get -o json clusteroperator  cloud-credential |jq '.status.conditions[] | select(.type == "Upgradeable")'
{
  "lastTransitionTime": "2024-05-12T22:43:14Z",
  "message": "Upgradeable annotation cloudcredential.openshift.io/upgradeable-to on cloudcredential.operator.openshift.io/cluster object needs updating before upgrade. See Manually Creating IAM documentation for instructions on preparing a cluster for upgrade.",
  "reason": "MissingUpgradeableAnnotation",
  "status": "False",
  "type": "Upgradeable"
}


# View available upgrades
oc adm upgrade

# Check you can upgrade and add the appropiate annotation to the Cloud Credential Operator

./upgrade-check.sh "4.15.14"

```
