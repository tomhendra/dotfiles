#     : 
# prepend: path=('/home/some/bin' $path)
# append: path+=('/home/some/bin')

# Use project specific binaries before global ones
path+=('node_modules/.bin:vendor/bin' $path)
path+=('/usr/local/sbin' $path)
# pnpm
path+=('/Users/tom/Library/pnpm', $path)

# export to sub-processes (make it inherited by child processes)
export PATH
