#! /usr/bin/env bash

function set_vars() {
    # Read in env variables
    set -o allexport;
    source .env;
    set +o allexport;
    
    # Append the `WyzeCams/` directory to the NFS root
    case "$NFS_ROOT" in
        */)
            NFS_ROOT="${NFS_ROOT}WyzeCams/"
        ;;
        *)
            NFS_ROOT="${NFS_ROOT}/WyzeCams/"
        ;;
    esac

    # Init a vars to store dirs in
    CAM_REC_DIR_LIST=()
    VID_DIR_LIST=()
}

function get_dirs() {
    # Loop through all files in the $NFS_ROOT
    for cam_dir in $NFS_ROOT*; do
        # Test that the file is a directory
        if [ -d "$cam_dir" ]; then
            # For each record directory
            for cam_rec_dir in $cam_dir/record/*; do
                # Test that the file is a directory
                if [ -d "$cam_rec_dir" ]; then
                    # For each video dir
                    CAM_REC_DIR_LIST+=($cam_rec_dir)
                    for vid_dir in $cam_rec_dir/*; do
                        # Test that the file is a directory
                        if [ -d "$vid_dir" ]; then
                            # Store the dirs in an array
                            VID_DIR_LIST+=($vid_dir)
                        fi
                    done
                fi
            done
        fi
    done
}

function is_file_young() {
    # Test that the file exists
    if [ ! -f $1 ]; then
        # NFS might have dropped? lets exit
        echo "file ${1} does not exist!"
        exit 1
    fi
    
    # seconds in $REC_RETENTION_HOURS hours
    MAXAGE=$(bc <<< "${REC_RETENTION_HOURS}*60*60")
    # file age in seconds = current_time - file_modification_time.
    FILEAGE=$(($(date +%s) - $(stat -c '%Y' "${1}")))

    # Test the file age against the $REC_RETENTION_HOURS
    test $FILEAGE -lt $MAXAGE && {
        # If the file is young return true
        #echo "${1} is less than ${REC_RETENTION_HOURS} hours old"
        return 0
    }
    # If the file is old return false
    #echo "${1} is older than ${REC_RETENTION_HOURS} hours"
    return 1
}

function clean_recordings() {
    # Loop through all vid dirs
    for dir in ${VID_DIR_LIST[@]}; do
        # Ensure that it is a directory
        if [ -d "$dir" ]; then
            # Loop through all MP4 files in the directory
            for vid in ${dir}/*.mp4; do
                # Ensure that $vid is a file
                if [ -f "$vid" ]; then
                    # Ensure the video is older than the configured value of $REC_RETENTION_HOURS
                    if ! is_file_young $vid; then
                        echo "removing old file: $vid"
                        rm $vid
                    fi
                fi
            done
        fi
    done
}

function prune_dirs() {
    # Loop over all vid dirs
    for dir in ${VID_DIR_LIST[@]}; do
        # Ensure that it is a directory
        if [ -d "$dir" ]; then
            # Test if the dir is empty
            if [ ! "$(ls -A $dir)" ]; then
                echo "removing empty directory: $dir"
                rm -rf $dir
            fi
        fi
    done

    # Loop over all rec dirs
    for dir in ${CAM_REC_DIR_LIST[@]}; do
         # Ensure that it is a directory
        if [ -d "$dir" ]; then
            # Test if the dir is empty
            if [ ! "$(ls -A $dir)" ]; then
                echo "removing empty directory: $dir"
                rm -rf $dir
            fi
        fi
    done
}

set_vars;
get_dirs;
clean_recordings;
prune_dirs;
