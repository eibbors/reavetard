{spawn, exec} = require 'child_process'

task 'build', 'continually build the JavaScript code', ->
  coffee = spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> console.log data.toString().trim()

# TODO: docco / review comments
# task 'doc', 'rebuild the Docco documentation', ->
#   exec([
#     'docco src/'
#   ].join(' && '), (err) ->
#     throw err if err
#   )
