# ===============================
# Creating pipeline environements
# ===============================
oc new-project askme-dev --display-name="Ask Me - DEV"
oc new-project askme-test --display-name="Ask Me - TEST"


PUT /projects/MyProject HTTP/1.0
Content-Type: application/json;charset=UTF-8

{
  "description": "This is a demo project.",
  "submit_type": "CHERRY_PICK",
  "owners": [
    "MyProject-Owners"
  ]
}

# Adding rights to execute containers with anyuid in both dev and test environments
oc adm policy add-scc-to-group anyuid system:serviceaccounts:askme-dev
oc adm policy add-scc-to-group anyuid system:serviceaccounts:askme-test
# Adding rights to pull images in askme-dev namespace from askme-test namespace
oc adm policy add-role-to-group system:image-puller system:serviceaccounts:askme-test -n askme-dev

# ========================
# Setup S2I Image frontend
# ========================
oc new-build https://github.com/clerixmaxime/sti-grunt-nginx.git --context-dir=/1.0 --strategy=docker --to=sti-grunt-nginx -n askme-dev

# =====================
# Setup DEV environment
# =====================
oc project askme-dev
# 1 - Database
#   Launching build of the database
oc new-build https://github.com/clerixmaxime/askme-backend.git --context-dir=/database --strategy=docker --to=askme-db --name=askme-db -n askme-dev
#   Launching mysql database using askme credentials questions/x2YfU8vHqAATS7Sh
oc new-app --image-stream=askme-dev/askme-db --name=database --allow-missing-imagestream-tags -e MYSQL_ROOT_PASSWORD='pass' -e MYSQL_USER='questions' -e MYSQL_PASSWORD='x2YfU8vHqAATS7Sh' -n askme-dev
oc delete svc database -n askme-dev
oc expose dc/database --port=3306 --target-port=3306 -n askme-dev
#   Adding deployment-hook that triggers execution of questions.sql
oc set deployment-hook dc/database --post -c database -- /bin/sh -c 'hostname && sleep 20 && /opt/rh/rh-mysql57/root/usr/bin/mysql -h database -u root --password=pass -P 3306 < /var/lib/mysql/questions.sql' -n askme-dev
#   Redeployment of the database after adding hook.
oc rollout latest database -n askme-dev

# 2 - Backend
#   Classic build using S2I NodeJS official image.
oc new-build nodejs~https://github.com/clerixmaxime/askme-backend.git --to=askme-backend --name=askme-backend -n askme-dev
#   Launching backend, specifying the location of the database with DB_PORT_3306_TCP_ADDR env variable.
#   /!\ Created service listen on port 8080 instead of 8081.
oc new-app --image-stream=askme-dev/askme-backend --name=backend --allow-missing-imagestream-tags -e DB_PORT_3306_TCP_ADDR='database' -n askme-dev
oc delete svc backend -n askme-dev
oc expose dc/backend --port=8081 --target-port=8081 -n askme-dev
oc expose svc backend -n askme-dev

# 3 - Frontend
#   oc new-build sti-grunt-nginx~https://github.com/clerixmaxime/askme-backbone.git
#   /!\ The applicaiton should be uploaded to ADOP and the STI-grunt-nginx image available
oc new-build sti-grunt-nginx~https://github.com/clerixmaxime/askme-backbone.git --to=askme-backbone --name=askme-backbone -n askme-dev
oc new-app --image-stream=askme-dev/askme-backbone --allow-missing-imagestream-tags -n askme-dev
oc delete svc askme-backbone -n askme-dev
oc expose dc/askme-backbone --port=8080 --target-port=8080 -n askme-dev
oc expose svc askme-backbone -n askme-dev

# =====================
# Setup TEST environment
# =====================
oc project askme-test
# 1 - Database
#   Launching mysql database using askme credentials questions/x2YfU8vHqAATS7Sh
oc new-app --image-stream=askme-dev/askme-db --name=database --allow-missing-imagestream-tags -e MYSQL_ROOT_PASSWORD='pass' -e MYSQL_USER='questions' -e MYSQL_PASSWORD='x2YfU8vHqAATS7Sh' -n askme-test
oc delete svc database -n askme-test
oc expose dc/database --port=3306 --target-port=3306 -n askme-test
#   Adding deployment-hook that triggers execution of questions.sql
oc set deployment-hook dc/database --post -c database -- /bin/sh -c 'hostname && sleep 20 && /opt/rh/rh-mysql57/root/usr/bin/mysql -h database -u root --password=pass -P 3306 < /var/lib/mysql/questions.sql' -n askme-test
#   Redeployment of the database after adding hook.
oc rollout latest database -n askme-test

# 2 - Backend
#   Launching backend, specifying the location of the database with DB_PORT_3306_TCP_ADDR env variable.
oc new-app --image-stream=askme-dev/askme-backend --name=backend --allow-missing-imagestream-tags -e DB_PORT_3306_TCP_ADDR='database' -n askme-test
oc delete svc backend -n askme-test
oc expose dc/backend --port=8081 --target-port=8081 -n askme-test
oc expose svc backend -n askme-test

# 3 - Frontend
oc new-app --image-stream=askme-dev/askme-backbone --allow-missing-imagestream-tags -n askme-test
oc delete svc askme-backbone -n askme-test
oc expose dc/askme-backbone --port=8080 --target-port=8080 -n askme-test
oc expose svc askme-backbone -n askme-test

```
