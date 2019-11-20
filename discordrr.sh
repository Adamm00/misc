#!/bin/bash

# Discordrr - Sonarr & Radarr Discord Notification BOT
# By Adamm - https://github.com/Adamm00
# 21/11/2019

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

if [ -n "$sonarr_eventtype" ]; then
  echo "$sonarr_eventtype - $(date)" >> /scripts/sonarr-debug.txt
elif [ -n "$radarr_eventtype" ]; then
  echo "$radarr_eventtype - $(date)" >> /scripts/radarr-debug.txt
fi

if [ "$sonarr_eventtype" = "Test" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
  	"username": "$botname",
  	"avatar_url": "$avatar",
  	"embeds": [{
  		"title": "$sonarr_eventtype message from Sonarr",
  		"color": 15749200,
  		"description": "$(date)"
  	}]
  }
EOF
      )" $webhookurl
elif [ "$sonarr_eventtype" = "Grab" ]; then
  ssize="$(if [ "$sonarr_release_size" -gt "1073741824" ]; then echo "$sonarr_release_size 1073741824" | awk '{printf "%.2fGB \n", $1/$2}'; else echo $((sonarr_release_size / 1048576 ))MB; fi)"
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
  	"username": "$botname",
  	"avatar_url": "$avatar",
  	"content": "Downloading: $show ${grabseason}x${grabepisode} - $grabtitle ($sonarr_release_quality) ($sonarr_release_releasegroup) ($ssize) @everyone",
  	"embeds": [{
  		"title": "$show",
  		"color": 16753920,
  		"url": "http://www.thetvdb.com/?tab=series&id=${sonarr_series_tvdbid}",
  		"fields": [{
  				"name": "Series",
  				"value": "$show",
  				"inline": true
  			},
  			{
  				"name": "Title",
  				"value": "$grabtitle",
  				"inline": true
  			},
  			{
  				"name": "Episode",
  				"value": "${grabseason}x${grabepisode}",
  				"inline": true
  			},
  			{
  				"name": "Quality",
  				"value": "$sonarr_release_quality",
  				"inline": true
  			},
  			{
  				"name": "Release Group",
  				"value": "$sonarr_release_releasegroup",
  				"inline": true
  			},
  			{
  				"name": "Size",
  				"value": "$ssize",
  				"inline": true
  			}
  		],
  		"footer": {
  			"text": "$(date)",
  			"icon_url": "$avatar"
  		}
  	}]
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
  	"embeds": [{
  		"title": "$show",
  		"color": 2605644,
  		"url": "http://www.thetvdb.com/?tab=series&id=${sonarr_series_tvdbid}",
  		"fields": [{
  				"name": "Series",
  				"value": "$show",
  				"inline": true
  			},
  			{
  				"name": "Title",
  				"value": "$dltitle",
  				"inline": true
  			},
  			{
  				"name": "Episode",
  				"value": "${dlseason}x${dlepisode}",
  				"inline": true
  			},
  			{
  				"name": "Torrent",
  				"value": "$sonarr_episodefile_scenename",
  				"inline": true
  			}
  		],
  		"footer": {
  			"text": "$(date)",
  			"icon_url": "$avatar"
  		}
  	}]
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
    "content": "Renamed Show",
    "embeds": [{
      "title": "$show"
    }]
  }
EOF
      )" $webhookurl
elif [ "$sonarr_eventtype" = "HealthIssue" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
  	"username": "$botname",
  	"avatar_url": "$avatar",
  	"content": "Sonarr Health Issue Detected @everyone",
  	"embeds": [{
      "title": "$sonarr_health_issue_type",
      "color": 15749200,
      "url": "$sonarr_health_issue_wiki",
  		"fields": [{
  				"name": "Message",
  				"value": "$sonarr_health_issue_message",
  				"inline": false
  			}
  		],
  		"footer": {
  			"text": "$(date)",
  			"icon_url": "$avatar"
  		}
  	}]
  }
EOF
      )" $webhookurl
fi


if [ "$radarr_eventtype" = "Test" ]; then
  curl -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
    "username": "$botname",
    "avatar_url": "$avatar",
    "embeds": [{
      "title": "$radarr_eventtype message from Radarr",
      "color": 15749200,
      "description": "$(date)"
    }]
  }
EOF
      )" $webhookurl
elif [ "$radarr_eventtype" = "Grab" ]; then
  rsize="$(if [ "$radarr_release_size" -gt "1073741824" ]; then echo "$radarr_release_size 1073741824" | awk '{printf "%.2fGB \n", $1/$2}'; else echo $((radarr_release_size / 1048576 ))MB; fi)"
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
  	"username": "$botname",
  	"avatar_url": "$avatar",
  	"content": "Downloading: $radarr_movie_title [$radarr_release_quality] [$radarr_release_releasegroup] [$rsize] @everyone",
  	"embeds": [{
  		"title": "$radarr_movie_title",
  		"color": 16753920,
  		"url": "https://imdb.com/title/${radarr_movie_imdbid}",
  		"fields": [{
  				"name": "Movie",
  				"value": "$radarr_movie_title",
  				"inline": true
  			},
  			{
  				"name": "Quality",
  				"value": "$radarr_release_quality",
  				"inline": true
  			},
  			{
  				"name": "Release Group",
  				"value": "$radarr_release_releasegroup",
  				"inline": true
  			},
  			{
  				"name": "Torrent",
  				"value": "$radarr_release_title",
  				"inline": true
  			},
  			{
  				"name": "Size",
  				"value": "$rsize",
  				"inline": true
  			}
  		],
  		"footer": {
  			"text": "$(date)",
  			"icon_url": "$avatar"
  		}
  	}]
  }
EOF
      )" $webhookurl
elif [ "$radarr_eventtype" = "Download" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
  	"username": "$botname",
  	"avatar_url": "$avatar",
  	"content": "$(if [ "$radarr_isupgrade" = "True" ]; then echo "Upgrading"; else echo "Importing"; fi): $radarr_movie_title [$radarr_moviefile_quality] [$radarr_moviefile_releasegroup] @everyone",
  	"embeds": [{
  		"title": "$radarr_movie_title",
  		"color": 2605644,
  		"url": "https://imdb.com/title/${radarr_movie_imdbid}",
  		"fields": [{
  				"name": "Movie",
  				"value": "$radarr_movie_title",
  				"inline": true
  			},
  			{
  				"name": "Quality",
  				"value": "$radarr_moviefile_quality",
  				"inline": true
  			},
  			{
  				"name": "Release Group",
  				"value": "$radarr_moviefile_releasegroup",
  				"inline": true
  			},
  			{
  				"name": "Torrent",
  				"value": "$radarr_moviefile_scenename",
  				"inline": true
  			},
  			{
  				"name": "Path",
  				"value": "/share/Storage/Downloads/Movies/$(echo "$radarr_moviefile_path" | cut -d "/" -f3-)",
  				"inline": true
  			}
  		],
  		"footer": {
  			"text": "$(date)",
  			"icon_url": "$avatar"
  		}
  	}]
  }
EOF
      )" $webhookurl
elif [ "$radarr_eventtype" = "Rename" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
    "username": "$botname",
    "avatar_url": "$avatar",
    "content": "Renamed Movie",
    "embeds": [{
      "title": "$radarr_movie_title"
    }]
  }
EOF
      )" $webhookurl
elif [ "$radarr_eventtype" = "HealthIssue" ]; then
  curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "$(cat <<EOF
  {
  	"username": "$botname",
  	"avatar_url": "$avatar",
  	"content": "Radarr Health Issue Detected @everyone",
  	"embeds": [{
      "title": "$radarr_health_issue_type",
      "color": 15749200,
      "url": "$radarr_health_issue_wiki",
  		"fields": [{
  				"name": "Message",
  				"value": "$radarr_health_issue_message",
  				"inline": false
  			}
  		],
  		"footer": {
  			"text": "$(date)",
  			"icon_url": "$avatar"
  		}
  	}]
  }
EOF
      )" $webhookurl
fi
