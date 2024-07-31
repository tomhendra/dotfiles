# prepend: path=('/home/some/bin' $path)
# append: path+=('/home/some/bin')

# old...
# path+=('node_modules/.bin:vendor/bin' $path)
# path+=('/usr/local/sbin' $path)

# Use project specific binaries before global ones
path=(
    "${ANDROID_HOME}/platform-tools"
    'node_modules/.bin'
    'vendor/bin'
    '/usr/local/sbin'
    $path
)

# Export PATH to sub-processes (make it inherited by child processes)
export PATH