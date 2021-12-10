#!/bin/bash

set -ev

wget http://download.geofabrik.de/africa/ivory-coast-latest.osm.pbf --no-verbose --output-document=data.osm.pbf 2>&1

osm_transit_extractor -i data.osm.pbf

mkdir output

cat osm-transit-extractor_lines.csv |xsv search -s mode 'ferry|bus' |xsv search -s shape '^$' -v > lines_with_shapes.csv
ogr2ogr output/lines.geojson -dialect sqlite -sql "SELECT *, GeomFromText(shape) FROM lines_with_shapes" lines_with_shapes.csv -a_srs "WGS84"

cat lines_with_shapes.csv |xsv select '!shape' | xsv sort -s code | xsv sort -s network |xsv sort -s operator  > output/lines.csv

cat osm-transit-extractor_routes.csv |xsv search -s mode 'ferry|bus' |xsv select '!shape' > routes.csv

cp osm-transit-extractor_stop_points.csv output/stops.csv

ogr2ogr output/stops.geojson -dialect sqlite -sql "SELECT *, GeomFromText('POINT(' || lon || ' ' || lat || ')') FROM stops" output/stops.csv -a_srs "WGS84"

cd bifidus_cli

poetry run python bifidus_cli.py -l ../output/lines.csv -r ../routes.csv -u ../bifidus_config.csv -n AbidjanTransport > ../output/qa.md

