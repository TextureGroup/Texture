#! /bin/zsh

header_dirs=(
  'Details'
  'Layout'
  'Base'
  'Debug'
  'TextExperiment/Component'
)

header_paths=(
  'TextKit/ASTextNodeTypes.h'
  'TextKit/ASTextKitComponents.h'
  'TextExperiment/String/ASTextAttribute.h'
)


mkdir -p Source/include
cd Source

for path in $header_dirs; do
  for file in $path/**/*.h; do
    # get file name
    file_name=${file##*/}
    echo $file $file_name
    cd include
    /bin/ln -s -f ../$file $file_name
    cd -
  done
done

for file in ./*.h; do
  file_name=${file##*/}
  echo $file $file_name
  cd include
  /bin/ln -s -f ../$file $file_name
  cd -
done

for file in $header_paths; do
  file_name=${file##*/}
  echo $file $file_name
  cd include
  /bin/ln -s -f ../$file $file_name
  cd -
done