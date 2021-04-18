#!/bin/bash
DATUM=`date +"%Y%m%d_%H%M%S"`
DIR_OUT="$HOME/OSM/osmcz_guidepost_gpi/"
BITMAP=${DIR_OUT}OSMCZ_ROZCESTNIKY.bmp
FILENAME=OSMCZ_ROZCESTNIKY_$DATUM
USERNAME="osm.gpsfreemaps.net"
SERVER="osm.gpsfreemaps.net"
DESTPATH="/srv/www/gpsfreemaps.net/osm/www/rozcestniky_gpi/archiv/"
SOURCE_URL="https://osm.fit.vutbr.cz/OsmHiCheck/gp/?get_gpx&proximity=100"

#DEFAULT SCRIPT VARS

#UPLOAD GPI to remote server ?
UPLOAD=1

#CLEANING DOWNLOADED / CREATED FILES
CLEANUP=1

#ALERT to POIS - BEEP BEEP GPSr
ALERTS=1

#POI CATEGORY NAME in GPSr
CATEGORY="OSMCZ_ROZCESTNIKY"

#Distance when GPSr DO BEEP BEEP ? [m]
PROXIMITY=100

ERROR=0

dprint(){
# zapnuti logovani do syslogu nastavenim promenne "OUTPUT_LOG = 1"
# zapnuti logovani do konzole nastavenim promenne "OUTPUT_CON = 1"
# nastaveni logovani do specifickeho souboru nastavenim promenne "OUTPUT_TO_FILE=1"
# nastaveni cesty log souboru promennou "LOG_DIRECTORY"
# nastaveni jmena logsouboru promennou "LOG_FILE"
OUTPUT_LOG=0
OUTPUT_CON=1
OUTPUT_TO_FILE=1
LOG_DIRECTORY=$DIR_OUT
LOG_FILE=$LOG_DIRECTORY/OSMCZ_ROZCESTNIKY.log
DEBUG=3

TIMENOW=`date "+%y-%m-%d_%H-%M-%S"`

  case "$1" in
    "3")
      dprint_prefix="DEBUG_EXTRA"
    ;;
    "2")
      dprint_prefix="DEBUG:"
    ;;
    "1")
      dprint_prefix="INFO:"
    ;;
    "0")
      dprint_prefix="ERROR:"
    ;;
  esac

#pis log do log souboru
    if [ $OUTPUT_TO_FILE = "1" ]; then

      mkdir -p "$LOG_DIRECTORY"
      echo "$TIMENOW $OUTPUT_PREFIX $dprint_prefix $2" >> $LOG_FILE
    fi

# pis log do syslogu
  if [ $DEBUG -ge $1 ]; then
    if [ $OUTPUT_LOG = "1" ]; then
      logger "$OUTPUT_PREFIX $dprint_prefix $2"
    fi

#pis log do terminalu
    if [ $OUTPUT_CON = "1" ]; then
      echo "$TIMENOW $OUTPUT_PREFIX $dprint_prefix $2"
    fi
  fi
}

dprint 2 "----Script $0 BEGIN----"

if [ ! -e $DIR_OUT ];then
  mkdir -p $DIR_OUT
  dprint 2 "$DIR_OUT not exists, creating"
else
  dprint 2 "$DIR_OUT exists - OK"
fi


dprint 2 "Downloading file from $SOURCE_URL"
curl -s -k --create-dirs -o "$DIR_OUT/$FILENAME.gpx" "${SOURCE_URL}" 
if [ $? -ne 0 ]; then
  dprint 0 "Cant download file from $SOURCE_URL - EXIT(1)"
  exit 1
fi

dprint 2 "STARTING GPSBABEL - gpsbabel -w -i gpx -f $DIR_OUT/$FILENAME.gpx -o garmin_gpi,alerts=${ALERTS},category=${CATEGORY},descr,proximity=${PROXIMITY},unique=1,bitmap="OSMCZ_ROZCESTNIKY.bmp" -F $DIR_OUT/$FILENAME.gpi "
gpsbabel -w -i gpx -f $DIR_OUT/$FILENAME.gpx -o garmin_gpi,alerts=${ALERTS},category=${CATEGORY},descr,proximity=${PROXIMITY},unique=1,bitmap="${BITMAP}" -F $DIR_OUT/$FILENAME.gpi

if [ $UPLOAD -eq 1 ] ; then
  dprint 2 "Starting UPLOAD files to $SERVER "
  dprint 3 "scp -C $DIR_OUT/$FILENAME.gpi ${USERNAME}@${SERVER}:${DESTPATH}"
  scp -C $DIR_OUT/$FILENAME.gpi ${USERNAME}@${SERVER}:${DESTPATH}
 
  if [ $? -ne 0 ]; then
    ERROR=1
  fi

  dprint 3 "scp -C $DIR_OUT/$FILENAME.gpi ${USERNAME}@${SERVER}:/srv/www/gpsfreemaps.net/osm/www/rozcestniky_gpi"
  scp -C $DIR_OUT/$FILENAME.gpi ${USERNAME}@${SERVER}:/srv/www/gpsfreemaps.net/osm/www/rozcestniky_gpi/OSMCZ_ROZCESTNIKY_LATEST.gpi

  if [ $? -ne 0 ]; then
    ERROR=1
  fi

  if [ "$ERROR" == "0" ]; then
    dprint 0 "Something wrong happened when uploading files"
  else
    dprint 3 "Files uploaded - OK"
  fi
  dprint 2 "UPLOAD COMPLETE"
fi

#cleanup
if [ "$CLEANUP" -eq 1 ] ; then
  dprint 3 "Removing files $DIR_OUT/OSMCZ_ROZCESTNIKY_LATEST.gpi $DIR_OUT/$FILENAME.gpx $DIR_OUT/$FILENAME.gpi"
  rm $DIR_OUT/$FILENAME.gpx $DIR_OUT/$FILENAME.gpi
fi
dprint 2 "----Script $0 END----"
