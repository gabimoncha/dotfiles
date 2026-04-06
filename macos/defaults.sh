#!/usr/bin/env bash

set -euo pipefail

defaults write NSGlobalDomain AppleLocale -string "en_US@currency=RON"

printf 'Applied macOS defaults.\n'
