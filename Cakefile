fs = require 'fs'
sys = require 'util'
{exec} = require 'child_process'
Md = require 'markdown-js'

logPath = "logs.md"

task "build", "Build the logs index file", (options) ->
  markdownContent = fs.readFileSync 'logs.md', 'ascii'
  postContent = Md.encode markdownContent
  layoutContent = fs.readFileSync '.cache/layout.html', 'ascii'
  combinedContent = layoutContent + postContent
  fs.writeFileSync 'logs.html', combinedContent

