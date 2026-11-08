// Local control file requests n8n's own graceful SIGTERM handler on Windows.
const fs = require('node:fs');
const path = require('node:path');
const root = __dirname;
const stopFile = path.join(root, 'run', 'stop.request');
const pidFile = path.join(root, 'run', 'n8n.pid');
fs.mkdirSync(path.dirname(pidFile), { recursive: true });
fs.rmSync(stopFile, { force: true });
fs.writeFileSync(pidFile, String(process.pid));
process.on('exit', () => {
  try { fs.rmSync(pidFile, { force: true }); fs.rmSync(stopFile, { force: true }); } catch {}
});
const poll = setInterval(() => {
  if (fs.existsSync(stopFile) && process.listenerCount('SIGTERM') > 0) {
    clearInterval(poll);
    fs.rmSync(stopFile, { force: true });
    process.emit('SIGTERM');
  }
}, 500);
poll.unref();
const entry = path.join(root, 'app', 'node_modules', 'n8n', 'bin', 'n8n');
process.argv = [process.execPath, entry, 'start'];
require(entry);
