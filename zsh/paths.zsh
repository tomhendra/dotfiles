# prepend: path=('/home/some/bin' $path)
# append: path+=('/home/some/bin')

# Use project specific binaries before global ones
path=(
   "$PNPM_HOME"
    'node_modules/.bin'
    'vendor/bin'
    '/usr/local/sbin'
    "${ANDROID_HOME}/emulator"
    "${ANDROID_HOME}/platform-tools"
    "${HOME}/.local/share/solana/install/active_release/bin"
    $path
)


# Export PATH to sub-processes (make it inherited by child processes)
export PATH
