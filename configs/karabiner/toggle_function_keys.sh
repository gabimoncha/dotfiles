#!/bin/bash

current_state=$(defaults read -g com.apple.keyboard.fnState)

if [ "$current_state" -eq 0 ]; then
  defaults write -g com.apple.keyboard.fnState -bool true
else
  defaults write -g com.apple.keyboard.fnState -bool false
fi

killall SystemUIServer
