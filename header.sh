#! /bin/zsh

header_dirs=(
  'Source/Details'
  'Source/Layout'
  'Source/Base'
  'Source/Debug'
  'Source/TextExperiment/Component'
)

header_paths=(
  'Source/TextKit/ASTextNodeTypes.h'
  'Source/TextKit/ASTextKitComponents.h'
  'Source/TextExperiment/String/ASTextAttribute.h'
)

function move() {
  local file=$1
  echo $file
  mv $file Source/include
}

mkdir -p Source/include

for path in $header_dirs; do
  for file in $path/**/*.h; do
    move $file   
  done
done

for path in $header_paths; do
  move $path
done