#!/bin/bash

# DiscordRR - Sonarr Discord Notification BOT
# By Adamm - https://github.com/Adamm00
# 04/10/2019

botname="SkynetBOT"
avatar="https://i.imgur.com/jZk12SL.png"
url=""


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
      )" $url
elif [ "$sonarr_eventtype" = "Grab" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
     "username":"$botname",
     "avatar_url":"$avatar",
     "content":"Downloading: $sonarr_series_title ${sonarr_release_seasonnumber}x${sonarr_release_episodenumbers} - $sonarr_release_episodetitles ($sonarr_release_quality) ($sonarr_release_releasegroup) ($((sonarr_release_size / 1048576 ))MB) @everyone",
     "embeds":[
        {
           "title":"$sonarr_series_title",
           "color":16753920,
           "url":"http://www.thetvdb.com/?tab=series&id=${sonarr_series_tvdbid}",
           "fields":[
              {
                 "name":"Series",
                 "value":"$sonarr_series_title",
                 "inline":true
              },
              {
                 "name":"Title",
                 "value":"$sonarr_release_episodetitles",
                 "inline":true
              },
              {
                 "name":"Episode",
                 "value":"${sonarr_release_seasonnumber}x${sonarr_release_episodenumbers}",
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
      )" $url
elif [ "$sonarr_eventtype" = "Download" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
      {
        "username": "$botname",
        "avatar_url": "$avatar",
        "content": "$(if [ "$sonarr_isupgrade" = "True" ]; then echo "Upgrading"; else echo "Importing"; fi): $sonarr_series_title ${sonarr_episodefile_seasonnumber}x${sonarr_episodefile_episodenumbers} - $sonarr_episodefile_episodetitles ($sonarr_episodefile_quality) @everyone",
        "embeds": [
          {
            "title": "$sonarr_series_title",
            "color": 2605644,
            "url": "http://www.thetvdb.com/?tab=series&id=${sonarr_series_tvdbid}",
            "fields":[
               {
                  "name":"Series",
                  "value":"$sonarr_series_title",
                  "inline":true
               },
               {
                  "name":"Title",
                  "value":"$sonarr_episodefile_episodetitles",
                  "inline":true
               },
               {
                  "name":"Episode",
                  "value":"${sonarr_episodefile_seasonnumber}x${sonarr_episodefile_episodenumbers}",
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
      )" $url
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
            "title": "$sonarr_series_title"
          }
        ]
      }
EOF
      )" $url
fi
