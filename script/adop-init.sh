#INIT SCRIPT

oc new-project adop
echo '{
  "apiVersion": "v1",
  "kind": "ServiceAccount",
  "metadata": {
    "name": "adop"
  },
  "secrets": [
    {"name": "adop-account"}
  ]
}' | oc create -f -

oadm policy add-scc-to-user anyuid -z adop -n adop
oadm policy add-role-to-user edit system:serviceaccount:adop:adop
