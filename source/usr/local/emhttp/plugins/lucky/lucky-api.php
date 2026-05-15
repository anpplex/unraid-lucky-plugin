<?php
$plugin = 'lucky';
$jobScript = "/usr/local/emhttp/plugins/$plugin/scripts/lucky-control-job";

header('Content-Type: text/plain; charset=UTF-8');

function lucky_api_tail_file($path, $lines = 180) {
  if (!is_readable($path)) {
    return '';
  }

  $size = filesize($path);
  if ($size === false || $size <= 0) {
    return '';
  }

  $maxBytes = 262144;
  $start = max(0, $size - $maxBytes);
  $handle = fopen($path, 'rb');
  if ($handle === false) {
    return '';
  }

  fseek($handle, $start);
  if ($start > 0) {
    fgets($handle);
  }

  $content = stream_get_contents($handle);
  fclose($handle);
  if ($content === false || $content === '') {
    return '';
  }

  $rows = preg_split('/\r\n|\r|\n/', rtrim($content));
  $output = implode("\n", array_slice($rows, -$lines));
  return trim($output);
}

function lucky_api_logs() {
  $chunks = [];
  $logs = [
    'Lucky control log' => '/var/log/lucky-control.log',
    'Lucky plugin and upstream update log' => '/var/log/lucky-plugin-update.log',
    'Lucky service log' => '/var/log/lucky.log',
  ];

  foreach ($logs as $title => $path) {
    $content = lucky_api_tail_file($path, 180);
    if ($content !== '') {
      $chunks[] = "== $title ==\n" . $content;
    }
  }

  if (empty($chunks)) {
    return 'No Lucky logs yet.';
  }

  return trim(implode("\n\n", $chunks));
}

function lucky_api_queue_job($script, $job) {
  if (!is_executable($script)) {
    return 'Lucky control job script is not available.';
  }

  $command = escapeshellcmd($script) . ' ' . escapeshellarg($job);
  exec($command . ' >/dev/null 2>&1 &');
  return 'Queued Lucky action: ' . $job . "\nOpen the log panel to watch progress.";
}

$action = $_POST['action'] ?? '';

if ($action === 'logs') {
  echo lucky_api_logs();
  exit;
}

$jobs = [
  'start' => 'start',
  'stop' => 'stop',
  'restart' => 'restart',
  'check_plugin_update' => 'check_plugin_update',
  'install_plugin_update' => 'install_plugin_update',
  'check_upstream_update' => 'check_upstream_update',
  'install_upstream_update' => 'install_upstream_update',
];

if (isset($jobs[$action])) {
  echo lucky_api_queue_job($jobScript, $jobs[$action]);
  exit;
}

http_response_code(400);
echo 'Unknown action.';
