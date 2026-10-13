const fs=require('node:fs'), M=require('./stroke-editor-model.js');
try { M.validate(JSON.parse(fs.readFileSync(0,'utf8'))); }
catch(error) { console.error(error.message); process.exitCode=1; }
