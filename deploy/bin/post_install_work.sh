#!/bin/sh
##
#   Setup Magento instance after install with Composer.
#   (all placeholders ${...} should be replaced by real values from ./work/template.json file)
##


# type of the deployment (skip some steps when app is deployed in TRAVIS CI, $DEPLOYMENT_TYPE='test')
DEPLOYMENT_TYPE=${DEPLOYMENT_TYPE}
# local specific environment
LOCAL_ROOT=${LOCAL_ROOT}    # root folder for the deployed instance
M2_ROOT=$LOCAL_ROOT       # root folder for Magento app (in common case can be other than LOCAL_ROOT)
# The owner of the Magento file system:
#   * Must have full control (read/write/execute) of all files and directories.
#   * Must not be the web server user; it should be a different user.
# Web server:
#   * must be a member of the '${LOCAL_GROUP}' group.
LOCAL_OWNER=${LOCAL_OWNER}
LOCAL_GROUP=${LOCAL_GROUP}
# DB connection params
DB_HOST=${CFG_DB_HOST}
DB_NAME=${CFG_DB_NAME}
DB_USER=${CFG_DB_USER}
# use 'skip_password' to connect to server w/o password.
DB_PASS=${CFG_DB_PASSWORD}
if [ "$DB_PASS" = "skip_password" ]; then
    MYSQL_PASS=""
    MAGE_DBPASS=""
else
    MYSQL_PASS="--password=$DB_PASS"
    MAGE_DBPASS="--db-password=""${CFG_DB_PASSWORD}"""
fi
# DB prefix can be empty
DB_PREFIX="${CFG_DB_PREFIX}"
if [ "$DB_PREFIX" = "" ]; then
    MAGE_DBPREFIX=""
else
    MAGE_DBPREFIX="--db-prefix=$DB_PREFIX"
fi

##
echo "Restore write access on folder '$M2_ROOT/app/etc' for owner when launches are repeated."
##
if [ -d "$M2_ROOT/app/etc" ]
then
    chmod -R go+w $M2_ROOT/app/etc
fi



##
echo "Drop/create database $DB_NAME."
##
mysqladmin -f -u"$DB_USER" $MYSQL_PASS -h"$DB_HOST" drop "$DB_NAME"
mysqladmin -f -u"$DB_USER" $MYSQL_PASS -h"$DB_HOST" create "$DB_NAME"



##
echo "(Re)install Magento using database '$DB_NAME' (connecting as '$DB_USER')."
##

# Full list of the available options:
# http://devdocs.magento.com/guides/v2.0/install-gde/install/cli/install-cli-install.html#instgde-install-cli-magento

php $M2_ROOT/bin/magento setup:install  \
--admin-firstname="${CFG_ADMIN_FIRSTNAME}" \
--admin-lastname="${CFG_ADMIN_LASTNAME}" \
--admin-email="${CFG_ADMIN_EMAIL}" \
--admin-user="${CFG_ADMIN_USER}" \
--admin-password="${CFG_ADMIN_PASSWORD}" \
--base-url="${CFG_BASE_URL}" \
--backend-frontname="${CFG_BACKEND_FRONTNAME}" \
--db-host="${CFG_DB_HOST}" \
--db-name="${CFG_DB_NAME}" \
--db-user="${CFG_DB_USER}" \
--language="${CFG_LANGUAGE}" \
--currency="${CFG_CURRENCY}" \
--timezone="${CFG_TIMEZONE}" \
--use-rewrites="${CFG_USE_REWRITES}" \
--use-secure="${CFG_USE_SECURE}" \
--use-secure-admin="${CFG_USE_SECURE_ADMIN}" \
--admin-use-security-key="${CFG_ADMIN_USE_SECURITY_KEY}" \
--session-save="${CFG_SESSION_SAVE}" \
--cleanup-database \
$MAGE_DBPREFIX \
$MAGE_DBPASS \

##
echo "Post installation setup for database '$DB_NAME'."
##
#
mysql --database=$DB_NAME --host=$DB_HOST --user=$DB_USER $MYSQL_PASS -e "source $LOCAL_ROOT/../bin/setup.sql"


if [ "$DEPLOYMENT_TYPE" = "test" ]; then
    echo "\nSkip file system ownership and permissions setup."
else
    ##
    echo "\nSwitch Magento 2 into 'developer' mode."
    php $M2_ROOT/bin/magento deploy:mode:set developer
    echo "Disable Magento 2 cache."
    php $M2_ROOT/bin/magento cache:disable
    echo "Run Magento 2 re-index."
    php $M2_ROOT/bin/magento indexer:reindex
    echo "Run Magento 2 cron."
    php $M2_ROOT/bin/magento cron:run
    ##
    echo "\nSet file system ownership and permissions."
    ##
#    mkdir -p $M2_ROOT/var/cache
#    mkdir -p $M2_ROOT/var/generation
    chown -R $LOCAL_OWNER:$LOCAL_GROUP $M2_ROOT
    #find $M2_ROOT -type d -exec chmod 770 {} \;
    #find $M2_ROOT -type f -exec chmod 660 {} \;
    chmod -R g+w $M2_ROOT/var
    chmod -R g+w $M2_ROOT/pub
    chmod u+x $M2_ROOT/bin/magento
    chmod -R go-w $M2_ROOT/app/etc
fi


##
echo "Post installation setup is done."
##