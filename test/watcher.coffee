test_path = path.join(base_path, 'compile')

class Watcher
  constructor: (@root) ->
    @output = path.join(@root, 'public')

  compile_change_compare: (src, output, comp, cb) ->
    initalStamp = null
    first_compile = =>
      initalStamp = @stat_file(output)

    @compile_and_change_file src, first_compile, (err) =>
      if err then return cb(err)
      initalStamp.should.be[comp](@stat_file(output))
      cb()

  compile_and_change_file: (file, first_compile, cb) ->
    count = 0
    project = new Roots(@root)
    project
      .on('error', cb)
      .on 'done', ->
        if ++count is 1 then return first_compile()
        watcher.close()
        cb()

    watcher = null
    project.watch().then (res) -> watcher = res

    setTimeout =>
      p = path.join(@root, file)
      fs.appendFileSync(p, ' ')
      fs.writeFileSync(p, fs.readFileSync(p, 'utf8').trim())
    , 3000

  stat_file: (file) ->
    fs.statSync(path.join(@output, file)).mtime.getTime()

describe 'watch', ->

  before ->
    @watcher = new Watcher(path.join(test_path, 'basic'))

  it 'should recompile on file change', (done) ->
    @watcher.compile_change_compare('index.jade', 'index.html', 'below', done)

  it 'should not recompile when an ignored file is changed', (done) ->
    timer = setTimeout(done, 1000)

    @watcher.compile_and_change_file 'package.json', (->), (err) ->
      clearTimeout(timer)
      done(true)
