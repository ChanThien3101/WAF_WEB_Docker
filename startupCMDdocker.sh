#!/bin/bash


# Start MariaDB
echo "Starting MariaDB..."
service mysql start
if [ $? -ne 0 ]; then
  echo "Failed to start MariaDB."
  exit 1
else
  echo "MariaDB started successfully."
fi

# Start Filebeat
echo "Starting Filebeat..."
service filebeat start
if [ $? -ne 0 ]; then
  echo "Failed to start Filebeat."
  exit 1
else
  echo "Filebeat started successfully."
fi

# Start Packetbeat
# echo "Starting Packetbeat..."
# service packetbeat start
# if [ $? -ne 0 ]; then
#   echo "Failed to start Packetbeat."
#   exit 1
# else
#   echo "Packetbeat started successfully."
# fi

# Start Apache
echo "Starting Apache..."
apache2ctl -D FOREGROUND
if [ $? -ne 0 ]; then
  echo "Failed to start Apache."
  exit 1
else
  echo "Apache started successfully."
fi
