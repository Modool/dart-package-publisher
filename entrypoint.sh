#!/bin/bash

set -e

export PATH="$PATH":"$HOME/.pub-cache/bin"

check_required_inputs() {
  echo "Check inputs..."
  if [ -z "$INPUT_CREDENTIALJSON" ]; then
    echo "Missing credentialJson, trying tokens"
    if [ -z "$INPUT_ACCESSTOKEN" ]; then
      echo "Missing accessToken"
      exit 1
    fi
    if [ -z "$INPUT_REFRESHTOKEN" ]; then
      echo "Missing refreshToken"
      exit 1
    fi
  fi
  echo "OK"
}

switch_working_directory() {
  if [ -z "$INPUT_RELATIVEPATH" ]; then
    :
  else
    echo "Switching to package directory '$INPUT_RELATIVEPATH'"
    cd "$INPUT_RELATIVEPATH"
  fi
  echo "Package dir: $PWD"
}

publish() {
  flutter doctor

  mkdir -p ~/.pub-cache
  if [ -z "$INPUT_CREDENTIALJSON" ]; then
    cat <<-EOF > ~/.pub-cache/credentials.json
    {
      "accessToken":"$INPUT_ACCESSTOKEN",
      "refreshToken":"$INPUT_REFRESHTOKEN",
      "tokenEndpoint":"https://accounts.google.com/o/oauth2/token",
      "scopes": [ "openid", "https://www.googleapis.com/auth/userinfo.email" ],
      "expiration": 1577149838000
    }
EOF
  else
    echo "$INPUT_CREDENTIALJSON" > ~/.pub-cache/credentials.json
  fi

  flutter pub publish --dry-run

  if [ $? -eq 0 ]; then
    echo "Dry Run Successfull."
  else
    echo "Dry Run Failed, skip real publishing."
    exit 0
  fi
  if [ "$INPUT_DRYRUNONLY" = "true" ]; then
    echo "Dry run only, skip publishing."
  else
    flutter pub publish -f

    if [ $? -eq 0 ]; then
      echo "::set-output name=success::true"
    else
      echo "::set-output name=success::false"
    fi
  fi
}

check_required_inputs
switch_working_directory
publish || true
