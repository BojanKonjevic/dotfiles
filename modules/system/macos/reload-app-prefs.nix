{userConfig}: {
  bundleId,
  appName,
  settingsPlist,
  label ? appName,
}: ''
  echo "Applying ${label} settings..." >&2
  CURRENT_HASH=$(sudo -u "${userConfig.username}" /usr/bin/defaults read "${bundleId}" 2>/dev/null | /usr/bin/openssl md5)
  sudo -u "${userConfig.username}" /usr/bin/defaults import "${bundleId}" "${settingsPlist}"
  NEW_HASH=$(sudo -u "${userConfig.username}" /usr/bin/defaults read "${bundleId}" 2>/dev/null | /usr/bin/openssl md5)
  if [ "$CURRENT_HASH" != "$NEW_HASH" ]; then
    sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
    sudo -u "${userConfig.username}" /usr/bin/killall -9 "${appName}" >/dev/null 2>&1 || true
    sleep 0.5
    sudo -u "${userConfig.username}" open -a "${appName}"
  fi
''
