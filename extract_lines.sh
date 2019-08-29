#!/bin/bash

set -ev

wget http://download.geofabrik.de/africa/ivory-coast-latest.osm.pbf --no-verbose --output-document=data.osm.pbf 2>&1

osm_transit_extractor -i data.osm.pbf

mkdir output

cp osm-transit-extractor_lines.csv output/lines.csv
cp osm-transit-extractor_stop_points.csv output/stops.csv

#transform to geojson
cat osm-transit-extractor_lines.csv|xsv select 1-8 |xsv search -s shape '^$' -v > lines_with_shapes.csv
ogr2ogr output/lines.geojson -dialect sqlite -sql "SELECT *, GeomFromText(shape) FROM lines_with_shapes" lines_with_shapes.csv -a_srs "WGS84"

ogr2ogr output/stops.geojson -dialect sqlite -sql "SELECT *, GeomFromText('POINT(' || lon || ' ' || lat || ')') FROM stops" output/stops.csv -a_srs "WGS84"
