#!/usr/bin/env bash

boot_run_with_nohup() {
    echo "bash ./mvnw spring-boot:run >$LogFile 2>&1 &"
    nohup bash ./mvnw spring-boot:run >"$LogFile" 2>&1 &

    echo $! >"$PidFile"
    echo "The server is starting : $!"
}

java_jar_with_nohup() {
    echo "java -jar $JarFile --spring.profiles.active=pro >>$LogFile 2>&1 &"
    nohup java -jar "$JarFile" --spring.profiles.active=pro >>"$LogFile" 2>&1 &

    echo $! >"$PidFile"
    echo "The server is starting : $!"
}

package_if_unpacked() {
    if [[ -d $JarPath ]]; then
        JarFile=$(find "$JarPath" -name '*.jar' | tail -1)
    fi
    if [[ -z $JarFile ]]; then
        maven_clean_package
    else
        rm -f "$LogFile"
    fi
}

maven_clean_package() {
    echo "bash ./mvnw clean package >$LogFile 2>&1"
    bash ./mvnw clean package >"$LogFile" 2>&1
}

exit_if_build_faild() {
    JarFile=$(find target -name '*.jar' | tail -1)

    if [[ -z $JarFile ]]; then
        echo "An error occurred during packaging"
        exit 1
    fi
}

test_is_app_running() {
    if [[ -f $PidFile ]]; then
        PidText=$(cat "$PidFile")
        if [[ -n $PidText ]]; then
            PsCount=$(ps -p "$PidText" | wc -l)
            if [[ $PsCount -eq 2 ]]; then
                Running="true"
            else
                rm -f "$PidFile"
            fi
        fi
    fi
}

exit_if_app_running() {
    if [[ $Running == "true" ]]; then
        echo "The server cannot be started, it has already started : $PidText"
        exit 2
    fi
}

kill_if_app_running() {
    if [[ $Running == "true" ]]; then
        echo "The server is stopping : $PidText"
        kill "$PidText"
        rm "$PidFile"
        sleep 1
    fi
}

# 环境准备
DirName=$(dirname "$0")
HomeDir=$(realpath "$DirName")
JarPath="$HomeDir/target"
ExecDir=$HomeDir/var
LogFile="$ExecDir/std.log"
PidFile="$ExecDir/run.pid"
ParamCmd=${1:-help}

cd "$HomeDir" || exit
mkdir -p "$ExecDir"
test_is_app_running

case $ParamCmd in
st | start) [[ $2 == "-f" ]] && ParamCmd="restart" ;;
esac

# 程序开始
case $ParamCmd in
d | dt | dev)
    kill_if_app_running

    boot_run_with_nohup

    tail -f "$LogFile"
    ;;
st | start)
    exit_if_app_running

    package_if_unpacked

    exit_if_build_faild

    java_jar_with_nohup
    ;;
rt | restart)
    maven_clean_package

    exit_if_build_faild

    kill_if_app_running

    java_jar_with_nohup
    ;;
vt | status)
    if [[ $Running == "true" ]]; then
        echo "The server is running : $PidText"
    else
        echo "The server is not running"
    fi
    ;;
qt | stop)
    if [[ $Running == "true" ]]; then
        kill_if_app_running
    else
        echo "The server is not running"
    fi
    ;;
sl | log)
    if [[ $2 == "-f" ]]; then
        tail -f "$LogFile"
    else
        less "$LogFile"
    fi
    ;;
help | *)
    echo "usage: bash app.sh [d|dt|dev]"
    echo "usage: bash app.sh [st|start] [-f]"
    echo "usage: bash app.sh [rt|restart]"
    echo "usage: bash app.sh [vt|status]"
    echo "usage: bash app.sh [qt|stop]"
    echo "usage: bash app.sh [sl|log] [-f]"
    ;;
esac
