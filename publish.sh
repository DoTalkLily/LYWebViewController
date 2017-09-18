#!/bin/sh

TAG=
VERBOSE=false

# modify the evironment HERE
# SPEC_REPO: 本地repo的名字。通过 pod repo add $SPEC_REPO $REPO_URL来实现初始化
# SPEC_PATH：要push上去的podsepc
# SOURCES：依赖哪些私有repo库
SOURCES=""
SPEC_REPO="LYWebViewController"
SPEC_PATH="LYWebViewController.podspec"

while getopts "t:vh" arg; do
  case $arg in
    t)
      TAG=$OPTARG
      ;;
    v)
      VERBOSE=true
      ;;
    h)
      usage
      ;;
    ?)
      echo "unknown argument"
      exit 1
      ;;
  esac
done

usage()
{
  echo "$0 -t <tagname>"
  echo "    Publish a new tag into pod spec repo. Before this, you should have pushed the new commit to remote, with tag updated in podspec file."
  echo "$0 -t <tagname> -v"
  echo "    Publish with verbose output message."
  echo "$0 -h"
  echo "    Show usage."
  exit 1
}

if test -z "$TAG"; then
  usage
fi

#################################################

git tag $TAG
git push --tags

if $VERBOSE; then
  pod repo push $SPEC_REPO $SPEC_PATH --sources=$SOURCES --use-libraries --allow-warnings --verbose
else
  pod repo push $SPEC_REPO $SPEC_PATH --sources=$SOURCES --use-libraries --allow-warnings
fi
pod trunk push $SPEC_PATH --allow-warnings
