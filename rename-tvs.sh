#!/bin/bash

function log() {
	>&2 echo $@;
}

if [ -z "$SEASON_PATTERN" ]; then
	SEASON_PATTERN='S%02d'
fi
if [ -z "$EPISODE_PATTERN" ]; then
	EPISODE_PATTERN='E%02d'
fi

# Initialize variables
run_cmd="mv"
name_filter=""
prefix=""
suffix=""
season=""
episode=""
start_season=1
start_episode=1
maxdepth=1

# Flags and arrays
debug="no"
check="no"
cont_num="no"
declare -a EXTRA_ARGS

while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name-filter)
      name_filter="-name '$2'"
      shift; shift;;
	-p|--prefix)
      prefix="$2"
      shift; shift;;
	-s|--suffix)
      suffix=".$2"
      shift; shift;;
	-S|--season)
	  printf -v season "$SEASON_PATTERN" "$2"
      shift; shift;;
	-E|--episode)
	  printf -v episode "$EPISODE_PATTERN" "$2"
      shift; shift;;
	--start-season)
	  start_season="$2"
      shift; shift;;
	--start-episode)
	  start_episode="$2"
      shift; shift;;
	-m|--maxdepth)
      maxdepth="$2"
      shift; shift;;
    -c|--check)
      check="yes"
      shift;;
	-d|--debug)
      debug="yes"
      shift;;
	-f|--full-num)
      cont_num="yes"
      shift;;
    -*|--*)
      echo "Unknown option $1"
      exit 1;;
    *)
      EXTRA_ARGS+=("$1")
      shift;;
  esac
done

if [ ${#EXTRA_ARGS[@]} -eq 0 ]; then
	EXTRA_ARGS+=(".")
fi

if [ "$check" = "yes" ]; then
	log "Running in check mode!"
	run_cmd="echo $run_cmd"
fi

dir_num="$start_season"
file_num="$start_episode"
for dst_dir in "${EXTRA_ARGS[@]}"
do
	# Check continuous numbering
	if [ "$cont_num" = "no" ]; then
		file_num="$start_episode"
	fi
	while IFS="" read -r -d "" path_to_file <&3
	do
		extension=$(echo $path_to_file | awk -F'.' '{print $(NF)}')
		real_filename=$(basename -s ".${extension}" "$path_to_file")
		if [ -z "$prefix" ]; then
			filename="$real_filename"
		else
			filename="$prefix"
		fi
		if [ -z "$season" ]; then
			printf -v season_n "$SEASON_PATTERN" "$dir_num"
		else
			season_n="$season"
		fi
		if [ -z "$episode" ]; then
			printf -v episode_n "$EPISODE_PATTERN" "$file_num"
		else
			episode_n="$episode"
		fi
		filedir=$(dirname "$path_to_file")
		renamed_file="${filename}.${season_n}${episode_n}${suffix}.${extension}"
		log "=== $real_filename -> $renamed_file"
		if [ "$check" != "yes" ] || [ "$debug" = "yes" ]; then
			$run_cmd "$path_to_file" "${filedir}/${renamed_file}"
		fi
		file_num=$((file_num+1))
	done 3< <(find "$dst_dir" -maxdepth $maxdepth -type f $name_filter -print0 | sort -z)
	dir_num=$((dir_num+1))
done
