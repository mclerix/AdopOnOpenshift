#!/bin/bash
# OpenShift Project
APP_NAME=$1
PROJECT_NAME=$2
SUB_DOMAIN=$3

# Adding rights to execute containers with anyuid in dev, test and prod environments
oc adm policy add-scc-to-group anyuid system:serviceaccounts:$PROJECT_NAME-dev
oc adm policy add-scc-to-group anyuid system:serviceaccounts:$PROJECT_NAME-test
oc adm policy add-scc-to-group anyuid system:serviceaccounts:$PROJECT_NAME-prod

# =====================
# Setup DEV environment
# =====================
oc project $PROJECT_NAME-dev
# 1 - Database
#   Launching build of the database
oc new-build http://adop:adop@gerrit-$PROJECT_NAME.$SUB_DOMAIN/gerrit/ExampleWorkspace/ExampleProject/askme-backend --context-dir=/database --strategy=docker --to=$APP_NAME-db --name=$APP_NAME-db -n $PROJECT_NAME-dev
#   Launching mysql database using askme credentials questions/x2YfU8vHqAATS7Sh
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-db --name=database --allow-missing-imagestream-tags -e MYSQL_ROOT_PASSWORD='pass' -e MYSQL_USER='questions' -e MYSQL_PASSWORD='x2YfU8vHqAATS7Sh' -n $PROJECT_NAME-dev
oc delete svc database -n $PROJECT_NAME-dev
oc expose dc/database --port=3306 --target-port=3306 -n $PROJECT_NAME-dev
#   Adding deployment-hook that triggers execution of questions.sql
oc set deployment-hook dc/database --post -c database -- /bin/sh -c 'hostname && sleep 20 && /opt/rh/rh-mysql57/root/usr/bin/mysql -h database -u root --password=pass -P 3306 < /var/lib/mysql/questions.sql' -n $PROJECT_NAME-dev
#   Redeployment of the database after adding hook.
oc rollout latest database -n $PROJECT_NAME-dev

# 2 - Backend
#   Classic build using S2I NodeJS official image.
oc new-build nodejs~http://adop:adop@gerrit-$PROJECT_NAME.$SUB_DOMAIN/gerrit/ExampleWorkspace/ExampleProject/askme-backend --to=$APP_NAME-backend --name=$APP_NAME-backend -n $PROJECT_NAME-dev
#   Launching backend, specifying the location of the database with DB_PORT_3306_TCP_ADDR env variable.
#   /!\ Created service listen on port 8080 instead of 8081.
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-backend --name=backend --allow-missing-imagestream-tags -e DB_PORT_3306_TCP_ADDR='database' -n $PROJECT_NAME-dev
oc delete svc backend -n $PROJECT_NAME-dev
oc expose dc/backend --port=8081 --target-port=8081 -n $PROJECT_NAME-dev
oc expose svc backend -n $PROJECT_NAME-dev

# 3 - Frontend
#   oc new-build sti-grunt-nginx~https://github.com/clerixmaxime/askme-backbone.git
#   /!\ The application should be uploaded to ADOP and the STI-grunt-nginx image available
oc new-build sti-grunt-nginx~http://adop:adop@gerrit-$PROJECT_NAME.$SUB_DOMAIN/gerrit/ExampleWorkspace/ExampleProject/askme-backbone --to=$APP_NAME-backbone --name=$APP_NAME-backbone -n $PROJECT_NAME-dev
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-backbone --allow-missing-imagestream-tags -n $PROJECT_NAME-dev
oc delete svc $APP_NAME-backbone -n $PROJECT_NAME-dev
oc expose dc/$APP_NAME-backbone --port=8080 --target-port=8080 -n $PROJECT_NAME-dev
oc expose svc $APP_NAME-backbone -n $PROJECT_NAME-dev

# =====================
# Setup TEST environment
# =====================
oc project $PROJECT_NAME-test
# 1 - Database
#   Launching mysql database using askme credentials questions/x2YfU8vHqAATS7Sh
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-db --name=database --allow-missing-imagestream-tags -e MYSQL_ROOT_PASSWORD='pass' -e MYSQL_USER='questions' -e MYSQL_PASSWORD='x2YfU8vHqAATS7Sh' -n $PROJECT_NAME-test
oc delete svc database -n $PROJECT_NAME-test
oc expose dc/database --port=3306 --target-port=3306 -n $PROJECT_NAME-test
#   Adding deployment-hook that triggers execution of questions.sql
oc set deployment-hook dc/database --post -c database -- /bin/sh -c 'hostname && sleep 20 && /opt/rh/rh-mysql57/root/usr/bin/mysql -h database -u root --password=pass -P 3306 < /var/lib/mysql/questions.sql' -n $PROJECT_NAME-test
#   Redeployment of the database after adding hook.
oc rollout latest database -n $PROJECT_NAME-test

# 2 - Backend
#   Launching backend, specifying the location of the database with DB_PORT_3306_TCP_ADDR env variable.
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-backend --name=backend --allow-missing-imagestream-tags -e DB_PORT_3306_TCP_ADDR='database' -n $PROJECT_NAME-test
oc delete svc backend -n $PROJECT_NAME-test
oc expose dc/backend --port=8081 --target-port=8081 -n $PROJECT_NAME-test
oc expose svc backend -n $PROJECT_NAME-test

# 3 - Frontend
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-backbone --allow-missing-imagestream-tags -n $PROJECT_NAME-test
oc delete svc $APP_NAME-backbone -n $PROJECT_NAME-test
oc expose dc/$APP_NAME-backbone --port=8080 --target-port=8080 -n $PROJECT_NAME-test
oc expose svc $APP_NAME-backbone -n $PROJECT_NAME-test

# =====================
# Setup PROD environment
# =====================
oc project $PROJECT_NAME-prod
# 1 - Database
#   Launching mysql database using askme credentials questions/x2YfU8vHqAATS7Sh
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-db --name=database --allow-missing-imagestream-tags -e MYSQL_ROOT_PASSWORD='pass' -e MYSQL_USER='questions' -e MYSQL_PASSWORD='x2YfU8vHqAATS7Sh' -n $PROJECT_NAME-prod
oc delete svc database -n $PROJECT_NAME-prod
oc expose dc/database --port=3306 --target-port=3306 -n $PROJECT_NAME-prod
#   Adding deployment-hook that triggers execution of questions.sql
oc set deployment-hook dc/database --post -c database -- /bin/sh -c 'hostname && sleep 20 && /opt/rh/rh-mysql57/root/usr/bin/mysql -h database -u root --password=pass -P 3306 < /var/lib/mysql/questions.sql' -n $PROJECT_NAME-prod
#   Redeployment of the database after adding hook.
oc rollout latest database -n $PROJECT_NAME-prod

# 2 - Backend
#   Launching backend, specifying the location of the database with DB_PORT_3306_TCP_ADDR env variable.
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-backend --name=backend --allow-missing-imagestream-tags -e DB_PORT_3306_TCP_ADDR='database' -n $PROJECT_NAME-prod
oc delete svc backend -n $PROJECT_NAME-prod
oc expose dc/backend --port=8081 --target-port=8081 -n $PROJECT_NAME-prod
oc expose svc backend -n $PROJECT_NAME-prod

# 3 - Frontend
oc new-app --image-stream=$PROJECT_NAME-dev/$APP_NAME-backbone --allow-missing-imagestream-tags -n $PROJECT_NAME-prod
oc delete svc $APP_NAME-backbone -n $PROJECT_NAME-prod
oc expose dc/$APP_NAME-backbone --port=8080 --target-port=8080 -n $PROJECT_NAME-prod
oc expose svc $APP_NAME-backbone -n $PROJECT_NAME-prod

# =====================
# Deploy Pipeline
# =====================

oc process -f pipeline.yaml --param=APP=$APP_NAME --param=PROJECT=$PROJECT_NAME --param=SUBDOMAIN=$SUB_DOMAIN | oc create -n $PROJECT_NAME -f -

oadm policy add-role-to-user edit system:serviceaccount:$PROJECT_NAME:adop -n $PROJECT_NAME-dev
oadm policy add-role-to-user edit system:serviceaccount:$PROJECT_NAME:adop -n $PROJECT_NAME-test
oadm policy add-role-to-user edit system:serviceaccount:$PROJECT_NAME:adop -n $PROJECT_NAME-prod
