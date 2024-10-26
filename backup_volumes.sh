#!/bin/bash
BACKUP_DIR=$(pwd)/docker_volumes_backup
mkdir -p $BACKUP_DIR

for volume in $(docker volume ls -q); do
    echo "Backing up volume: $volume"
    docker run --rm -v $volume:/volume_data -v $BACKUP_DIR:/backup busybox tar cvf /backup/${volume}_backup.tar /volume_data
done

echo "All volumes have been backed up to $BACKUP_DIR"

