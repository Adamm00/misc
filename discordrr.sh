#!/bin/bash

# Discordrr - Sonarr Discord Notification BOT
# By Adamm - https://github.com/Adamm00
# 04/10/2019

botname="SkynetBOT"
avatar="https://i.imgur.com/jZk12SL.png"
webhookurl=""


show="$sonarr_series_title"
grabtitle="$sonarr_release_episodetitles"
grabseason="$sonarr_release_seasonnumber"
grabepisode="$sonarr_release_episodenumbers"
dltitle="$sonarr_episodefile_episodetitles"
dlseason="$sonarr_episodefile_seasonnumber"
dlepisode="$sonarr_episodefile_episodenumbers"


if [ "$sonarr_eventtype" = "Test" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
      {
        "username": "$botname",
        "avatar_url": "$avatar",
        "embeds": [
          {
            "title": "$sonarr_eventtype message from Sonarr",
            "color": 15749200,
            "description": "$(date "+%d/%m/%y %r")"
          }
        ]
      }
EOF
      )" $webhookurl
elif [ "$sonarr_eventtype" = "Grab" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
     "username":"$botname",
     "avatar_url":"$avatar",
     "content":"Downloading: $show ${grabseason}x${grabepisode} - $grabtitle ($sonarr_release_quality) ($sonarr_release_releasegroup) ($((sonarr_release_size / 1048576 ))MB) @everyone",
     "embeds":[
        {
           "title":"$show",
           "color":16753920,
           "url":"http://www.thetvdb.com/?tab=series&id=${sonarr_series_tvdbid}",
           "fields":[
              {
                 "name":"Series",
                 "value":"$show",
                 "inline":true
              },
              {
                 "name":"Title",
                 "value":"$grabtitle",
                 "inline":true
              },
              {
                 "name":"Episode",
                 "value":"${grabseason}x${grabepisode}",
                 "inline":true
              },
              {
                 "name":"Quality",
                 "value":"$sonarr_release_quality",
                 "inline":true
              },
              {
                 "name":"Release Group",
                 "value":"$sonarr_release_releasegroup",
                 "inline":true
              },
              {
                 "name":"Size",
                 "value":"$((sonarr_release_size / 1048576 ))MB",
                 "inline":true
              }
           ],
           "footer":{
              "text":"$(date)",
              "icon_url":"$avatar"
           }
        }
     ]
  }
EOF
      )" $webhookurl
elif [ "$sonarr_eventtype" = "Download" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
      {
        "username": "$botname",
        "avatar_url": "$avatar",
        "content": "$(if [ "$sonarr_isupgrade" = "True" ]; then echo "Upgrading"; else echo "Importing"; fi): $show ${dlseason}x${dlepisode} - $dltitle ($sonarr_episodefile_quality) @everyone",
        "embeds": [
          {
            "title": "$show",
            "color": 2605644,
            "url": "http://www.thetvdb.com/?tab=series&id=${sonarr_series_tvdbid}",
            "fields":[
               {
                  "name":"Series",
                  "value":"$show",
                  "inline":true
               },
               {
                  "name":"Title",
                  "value":"$dltitle",
                  "inline":true
               },
               {
                  "name":"Episode",
                  "value":"${dlseason}x${dlepisode}",
                  "inline":true
               },
               {
                  "name":"Torrent",
                  "value":"$sonarr_episodefile_scenename",
                  "inline":true
               }
            ],
            "footer": {
              "text": "$(date)",
              "icon_url": "$avatar"
            }
          }
        ]
      }
EOF
      )" $webhookurl
elif [ "$sonarr_eventtype" = "Rename" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
      {
        "username": "$botname",
        "avatar_url": "$avatar",
        "content": "Renamed",
        "embeds": [
          {
            "title": "$show"
          }
        ]
      }
EOF
      )" $webhookurl
fi
