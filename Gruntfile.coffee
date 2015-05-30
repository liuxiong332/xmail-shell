fs = require 'fs'
path = require 'path'
os = require 'os'
_ = require 'underscore-plus'

# Add support for obsolete APIs of vm module so we can make some third-party
# modules work under node v0.11.x.
require 'vm-compatibility-layer'

_ = require 'underscore-plus'

packageJson = require '../package.json'

module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-build-atom-shell')

  # This allows all subsequent paths to the relative to the root of the repo
  grunt.file.setBase(path.resolve('..'))

  if not grunt.option('verbose')
    grunt.log.writeln = (args...) -> grunt.log
    grunt.log.write = (args...) -> grunt.log

  tmpDir = os.tmpdir()

  pkgName = packageJson.name
  productName = packageJson.productName
  appName = if process.platform is 'darwin' then "#{productName}.app" else productName
  executableName = if process.platform is 'win32' then "#{productName}.exe" else productName
  executableName = executableName.toLowerCase() if process.platform is 'linux'

  buildDir = grunt.option('build-dir') ? path.join(tmpDir, "#{pkgName}-build")
  buildDir = path.resolve(buildDir)
  installDir = grunt.option('install-dir')

  home = process.env.HOME ? process.env.USERPROFILE

  symbolsDir = path.join(buildDir, "#{productName}.breakpad.syms")
  shellAppDir = path.join(buildDir, appName)

  if process.platform is 'win32'
    contentsDir = shellAppDir
    appDir = path.join(shellAppDir, 'resources', 'app')
    installDir ?= path.join(process.env.ProgramFiles, appName)
    killCommand = "taskkill /F /IM #{executableName}"
  else if process.platform is 'darwin'
    contentsDir = path.join(shellAppDir, 'Contents')
    appDir = path.join(contentsDir, 'Resources', 'app')
    installDir ?= path.join('/Applications', appName)
    killCommand = "pkill -9 #{executableName}"
  else
    contentsDir = shellAppDir
    appDir = path.join(shellAppDir, 'resources', 'app')
    installDir ?= process.env.INSTALL_PREFIX ? '/usr/local'
    killCommand = "pkill -9 #{executableName}"

  installDir = path.resolve(installDir)

  opts =
    name: pkgName

    pkg: grunt.file.readJSON('package.json')

    'build-atom-shell':
      tag: "v0.24.0"
      nodeVersion: '0.24.0'
      remoteUrl: "https://github.com/atom/atom-shell"
      buildDir: buildDir
      rebuildPackages: false
      projectName: pkgName
      productName: productName

  opts[pkgName] = {appDir, appName, symbolsDir, buildDir, contentsDir, installDir, shellAppDir, productName, executableName}

  grunt.initConfig(opts)

  defaultTasks = ['build-atom-shell']
  grunt.registerTask('default', defaultTasks)
