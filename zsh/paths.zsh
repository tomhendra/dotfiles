# ZSH allows special mapping of environment variables: 
# prepend: path=('/home/some/bin' $path)
# append: path+=('/home/some/bin')

# Use project specific binaries before global ones
path=('node_modules/.bin:vendor/bin' $path)

# export to sub-processes (make it inherited by child processes)
export PATH
