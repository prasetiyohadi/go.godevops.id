#!/usr/bin/env bash

echo "Build vim-go using Dagger CI"

if ! type -p dagger &>/dev/null; then
    printf '%s\n' "error: dagger is not installed, exiting..."
    exit 1
fi

# get source code from current host directory
source=$(dagger query <<EOF | jq -r '.host.directory.id'
{
  host {
    directory(path: ".") {
      id
    }
  }
}
EOF
)

# mount source code directory in golang container
# build Go binary
# export binary from container to host filesystem
build=$(dagger query <<EOF | jq -r .container.from.withDirectory.withWorkdir.withExec.file.export
{
  container {
    from(address:"golang:1.21.5") {
      withDirectory(path:"/src", directory:"$source") {
        withWorkdir(path:"/src") {
          withExec(args:["go", "build", "-o", "vim-go", "./cmd/vim-go"]) {
            file(path:"./vim-go") {
              export(path:"./bin/vim-go")
            }
          }
        }
      }
    }
  }
}
EOF
)

# check build result and display message
if [ "$build" == "true" ]
then
    echo "Build vim-go successful"
else
    echo "Build vim-go unsuccessful"
fi
