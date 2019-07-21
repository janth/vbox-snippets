#!/bin/bash

# vboxmanage getextradata global GUI/SuppressMessages
# Value: confirmInputCapture,remindAboutAutoCapture,remindAboutMouseIntegrationOff,remindAboutMouseIntegrationOn,remindAboutWrongColorDepth,remindAboutMouseIntegration

echo vboxmanage setextradata global GUI/SuppressMessages "all"
