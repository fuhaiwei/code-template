#!/usr/bin/env bash

# 环境准备
DirName=$(dirname "$0")
HomeDir=$(realpath "$DirName"/..)
ExecMvn="bash ./mvnw"
cd "$HomeDir" || exit

# 版本发布
git flow release start "$1"
$ExecMvn versions:set -DnewVersion="$1"
$ExecMvn versions:commit
git add .
git commit -m "Set version to $1"
git flow release finish "$1"
