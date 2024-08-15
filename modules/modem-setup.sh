#!/bin/bash

# Define retry parameters
MAX_RETRIES=5
RETRY_DELAY=10  # in seconds

# Function to check internet connectivity
check_internet() {
  curl -s --head http://www.google.com | head -n 1 | grep "200 OK" > /dev/null
  return $?
}

# Retry function
retry() {
  local n=0
  while [[ $n -lt $MAX_RETRIES ]]; do
    # Run modem setup commands
    sudo ip link set wwu1i4 down
    sleep 2
    echo 'Y' | sudo tee /sys/class/net/wwu1i4/qmi/raw_ip
    sleep 2
    sudo ip link set wwu1i4 up
    sleep 2
    sudo qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
    sleep 5
    sudo udhcpc -q -f -i wwu1i4

    # Check if internet is connected
    if check_internet; then
      echo "Internet connection established."
      return 0
    else
      echo "No internet connection. Retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
      n=$((n+1))
    fi
  done

  echo "Failed to establish internet connection after $MAX_RETRIES attempts."
  exit 1
}

# Execute the retry function
retry
