#!/bin/bash

# Set sane bash defaults
set -o errexit
set -o pipefail

OPTION="$1"
ACCESS_KEY=${ACCESS_KEY:?"ACCESS_KEY required"}
SECRET_KEY=${SECRET_KEY:?"SECRET_KEY required"}
S3PATH=${S3PATH:?"S3_PATH required"}
GPG_ENCRYPT_KEY=${GPG_ENCRYPT_KEY:?"GPG_ENCRYPT_KEY required"}
GPG_SIGN_KEY=${GPG_SIGN_KEY:?"GPG_SIGN_KEY required"}
GPG_SIGN_KEY_PASSPHRASE=${GPG_SIGN_KEY_PASSPHRASE:?"GPG_SIGN_KEY_PASSPHRASE required"}

CRON_SCHEDULE=${CRON_SCHEDULE:-0 * * * *}

echo "[Credentials]" > /root/.boto
echo "aws_access_key_id = $ACCESS_KEY" >> /root/.boto
echo "aws_secret_access_key = $SECRET_KEY" >> /root/.boto

LOCKFILE="/tmp/duplicity.lock"
LOG="/var/log/cron.log"

if [ ! -e $LOG ]; then
  touch $LOG
fi

if [[ $OPTION = "start" ]]; then
  CRONFILE="/etc/cron.d/duplicity"
  CRONENV=""

  echo "Found the following files and directores mounted under /data:"
  echo
  ls -F /data
  echo

  echo "Adding CRON schedule: $CRON_SCHEDULE"
  CRONENV="$CRONENV ACCESS_KEY=$ACCESS_KEY"
  CRONENV="$CRONENV SECRET_KEY=$SECRET_KEY"
  echo "$CRON_SCHEDULE root $CRONENV bash /run.sh backup" >> $CRONFILE

  echo "Starting CRON scheduler: $(date)"
  cron
  exec tail -f $LOG 2> /dev/null

elif [[ $OPTION = "backup" ]]; then
  echo "Starting duplicity sync: $(date)" | tee $LOG

  if [ -f $LOCKFILE ]; then
    echo "$LOCKFILE detected, exiting! Already running?" | tee -a $LOG
    exit 1
  else
    touch $LOCKFILE
  fi


  echo "Executing /usr/bin/duplicity --encrypt-key $ENCRYPT_KEY --sign-key $ENCRYPT_KEY --volsize 100 /data $S3PATH --archive-dir /archive" | tee -a $LOG
  /usr/bin/duplicity --encrypt-key $GPG_ENCRYPT_KEY --sign-key $GPG_SIGN_KEY /data $S3PATH --archive-dir /archive --allow-source-mismatch
  #/usr/local/bin/s3cmd sync $S3CMDPARAMS /data/ $S3PATH 2>&1 | tee -a $LOG
  rm -f $LOCKFILE
  echo "Finished: $(date)" | tee -a $LOG

else
  echo "Unsupported option: $OPTION" | tee -a $LOG
  exit 1
fi
