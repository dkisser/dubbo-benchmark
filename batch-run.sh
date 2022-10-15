#!/usr/bin/env bash

usage() {
    echo "Usage: ${PROGRAM_NAME} command dirname"
    echo "command: [m|s|p|f]"
    echo "         -m [profiling|benchmark], specify benchmark mode"
    echo "         -s hostname, host name"
    echo "         -p port, port number"
    echo "         -f output file path"
    echo "         -a other args"
    echo "         -S server mode"
    echo "         -r result file path"
    echo "dirname: test module name"
}

build() {
    mvn --projects benchmark-base,client-base,server-base,$1 clean package
}

java_options() {
    JAVA_OPTIONS="-server -Xmx1g -Xms1g -XX:MaxDirectMemorySize=1g -XX:+UseG1GC"
    if [ "x${MODE}" = "xprofiling" ]; then
        JAVA_OPTIONS="${JAVA_OPTIONS} \
            -XX:+UnlockCommercialFeatures \
            -XX:+FlightRecorder \
            -XX:StartFlightRecording=duration=30s,filename=$1.jfr \
            -XX:FlightRecorderOptions=stackdepth=256"
    fi
}

run() {
    if [ -d "$1/target" ]; then
        JAR=`find $1/target/*.jar | head -n 1`
        echo
        echo "RUN $1 IN ${MODE:-benchmark} MODE"
        CMD="java ${JAVA_OPTIONS} -Dserver.host=${SERVER} -Dserver.port=${PORT} -Dbenchmark.output=${OUTPUT} -Dbenchmark.output=${RESULT} -jar ${JAR} ${OTHERARGS}"
        echo "command is: ${CMD}"
        echo
        ${CMD}
    fi
}


PROGRAM_NAME=$0
MODE="benchmark"
SERVER="localhost"
PORT="8080"
OUTPUT=""
OPTIND=1
OTHERARGS=""
SERVER_MODE=0
RESULT=""

while getopts "m:s:p:f:a:S:r:" opt; do
    case "$opt" in
        m)
            MODE=${OPTARG}
            ;;
        s)
            SERVER=${OPTARG}
            ;;
        p)
            PORT=${OPTARG}
            ;;
        f)
            OUTPUT=${OPTARG}
            ;;
        a)
            OTHERARGS=${OPTARG}
            ;;
        S)
            SERVER_MODE=1
            ;;
        r)
            RESULT=${OPTARG}
            ;;
        ?)
            usage
            exit 0
            ;;
    esac
done

shift $((OPTIND-1))
PROJECT_DIR=$1

if [ ! -d "${PROJECT_DIR}" ]; then
    usage
    exit 0
fi


if [ ${SERVER_MODE} -ne 0 ];then
  # shellcheck disable=SC2068
  for str in $@; do
    build $str
    java_options $str
    run $str &
  done
  else
    # shellcheck disable=SC2068
    for str in $@; do
      build $str
      java_options $str
      run $str
    done
fi








