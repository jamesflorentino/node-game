fs = require 'fs'
sys = require 'util'
{exec} = require 'child_process'

logPath = "logs.md"

task "build", "Build the logs index file", (options) ->
	exec "redcarpet logs.md > ./.cache/logs.html", ->
		exec "cat ./.cache/layout.html ./.cache/logs.html > logs.html", ->
			console.log 'fuck yeah done!'

	return


###

fs = require 'fs'
sys = require 'util'
{exec} = require 'child_process'

markdownFile = "logs.md"

Cake =
	createDocumentation: ->
		fs.readFile markdownFile, (error, data) ->

			navMarkdown = ''
			contentMarkdown = ''
			# convert the raw data to an ASCII-fied string
			content = data.toString 'ascii'

			# get all the available h2 headers and store them as nav items
			methods = content.match /^## [\w]+/mg
			
			if !methods
				console.log "yo, you have no documentation yo!"
				return

			methods.forEach (el) ->
				link = el.replace /## ([a-zA-Z]+)/g, ($1, $2) -> "- [#{$2}](##{$2})"
				navMarkdown += "#{link} \n"

			# append the title with an anchorId
			contentMarkdown = content.replace /^## ([\w]+)/mg, ($1, $2) ->
				"#{$1} <a name=\"#{$2}\"></a>"

			fs.writeFile './.cache/content.md', contentMarkdown, (err) ->
				(if err then console.log err else console.log 'saved content.md')
			
			fs.writeFile './.cache/nav.md', navMarkdown, (err) ->
				(if err then console.log err else console.log 'saved nav.md')

			# generate html files
			exec 'redcarpet ./.cache/content.md > ./.cache/content.html', ->
				exec 'redcarpet ./.cache/nav.md > ./.cache/nav.html', ->

					navHtml = ''
					contentHtml = ''
					layoutHtml = ''

					fs.readFile './.cache/content.html', (err, data) ->
						contentHtml = data.toString 'ascii'
						fs.readFile './.cache/nav.html', (err, data) ->
							navHtml = data.toString 'ascii'
							fs.readFile './layout.html', (err, data) ->
								layoutHtml = data.toString 'ascii'
								documentationHtml = layoutHtml + ''
								documentationHtml = documentationHtml.replace '#{nav}', navHtml
								documentationHtml = documentationHtml.replace '#{content}', contentHtml
								fs.writeFile './index.html', documentationHtml, (err) ->
									console.log 'finished!'


task "build", "Build the documentation", (options) ->
	fs.readdir '.cache/', (err) ->
		if err?
			exec 'mkdir .cache', -> Cake.createDocumentation()
		else
			Cake.createDocumentation()


