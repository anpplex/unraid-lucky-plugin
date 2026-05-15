<?php
$plugin = 'lucky';
$rc = '/etc/rc.d/rc.lucky';
$updateScript = "/usr/local/emhttp/plugins/$plugin/scripts/lucky-plugin-update";
$upstreamUpdateScript = "/usr/local/emhttp/plugins/$plugin/scripts/lucky-upstream-update";

header('Content-Type: text/plain; charset=UTF-8');

function lucky_api_run($command, $args = []) {
  $parts = [escapeshellcmd($command)];
  foreach ($args as $arg) {
    $parts[] = escapeshellarg($arg);
  }
  return shell_exec(implode(' ', $parts) . ' 2>&1') ?: '';
}

function lucky_api_update($script, $action) {
  if (!is_executable($script)) {
    return 'Update script is not available.';
  }
  return lucky_api_run($script, [$action]);
}

function lucky_api_logs($rc) {
  $chunks = [];
  $updateLog = '/var/log/lucky-plugin-update.log';
  if (is_file($updateLog)) {
    $chunks[] = "== Lucky plugin and upstream update log ==\n" . (shell_exec('tail -n 180 ' . escapeshellarg($updateLog) . ' 2>/dev/null') ?: '');
  }
  $luckyLog = lucky_api_run($rc, ['logs', '180']);
  if (trim($luckyLog) !== '') {
    $chunks[] = "== Lucky service log ==\n" . $luckyLog;
  }
  return trim(implode("\n\n", $chunks));
}

$action = $_POST['action'] ?? '';

if ($action === 'logs') {
  echo lucky_api_logs($rc);
  exit;
}

if (in_array($action, ['start', 'stop', 'restart'], true)) {
  echo lucky_api_run($rc, [$action]);
  exit;
}

if (in_array($action, ['check_plugin_update', 'install_plugin_update'], true)) {
  echo lucky_api_update($updateScript, $action === 'install_plugin_update' ? 'install' : 'check');
  exit;
}

if (in_array($action, ['check_upstream_update', 'install_upstream_update'], true)) {
  echo lucky_api_update($upstreamUpdateScript, $action === 'install_upstream_update' ? 'install' : 'check');
  exit;
}

http_response_code(400);
echo 'Unknown action.';
