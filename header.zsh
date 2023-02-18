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

mkdir -p Source/include

which mv

for path in $header_dirs; do
  for file in $path/**/*.h; do
    echo $file    
    /bin/mv "$file" Source/include
  done
done

for file in $header_paths; do
  /bin/mv "$file" Source/include
done