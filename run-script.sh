#!/bin/sh

RENAISSANCE_DIR=${RENAISSANCE_DIR:-.}
RENAISSANCE_JAR_NAME=${RENAISSANCE_JAR_NAME:-renaissance-mit-0.12.0.jar}

HEAP_MEASURE_CPATH=${HEAP_MEASURE_CPATH:-../renaissance/plugins/heap-measure/target/classes}

DEFAULT_CSV="out-$(date +%s).csv"
OUTPUT_CSV=${1:-$DEFAULT_CSV}



java -jar "$RENAISSANCE_DIR/$RENAISSANCE_JAR_NAME" --plugin "$HEAP_MEASURE_CPATH"'!org.renaissance.plugins.heapmeasure.Main' --csv "$OUTPUT_CSV" $(awk '/^[^#]/ { printf $0 " " } END { print "" }' benchmarks.txt)
