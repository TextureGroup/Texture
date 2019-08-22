const { danger, fail, warn, schedule } = require('danger');
const { readFileSync } = require('fs');

const source_pattern = /(\.m|\.mm|\.h)$/;
const modified_source_files = danger.git.modified_files.filter(f => source_pattern.test(f));
const has_modified_source_files = (Array.isArray(modified_source_files) && modified_source_files.length > 0);
const added_source_files = danger.git.created_files.filter(f => source_pattern.test(f));
const has_added_source_files = (Array.isArray(added_source_files) && added_source_files.length > 0);

// Make it more obvious that a PR is a work in progress and shouldn't be merged yet
if (danger.github.pr.title.includes("[WIP]")) {
  const msg = "PR is classed as Work in Progress";
  console.error("FAIL: " + msg);
  fail(msg);
}

// Warn when there is a big PR
if (danger.github.pr.additions + danger.github.pr.deletions > 500) {
  const msg = "This is a big PR, please consider splitting it up to ease code review.";
  console.error("WARN: "+ msg);
  warn(msg);
}

// Modifying the changelog will probably get overwritten.
if (danger.git.modified_files.includes("CHANGELOG.md")) {
  if (danger.github.pr.title.includes("#changelog")) {
    const msg = "PR modifies CHANGELOG.md, which is a generated file. #changelog added to the title to suppress this warning.";
    console.error("WARN: "+ msg);
    warn(msg);
  } else {
    const msg = "PR modifies CHANGELOG.md, which is a generated file. Add #changelog to the title to suppress this failure.";
    console.error("FAIL: " + msg);
    fail(msg);
  }
}

// Reference: http://a32.me/2014/03/heredoc-multiline-variable-with-javascript/
function hereDoc(f) {
  return f.toString().
  replace(/^[^\/]+\/\*!?/, '').
  replace(/\*\/[^\/]+$/, '');
}

function full_license(partial_license, filename) {
  var license_header = hereDoc(function() {/*!
//
*/});
  license_header += "//  " + filename;
  license_header += hereDoc(function() {/*!
//  Texture
//*/});
  license_header += partial_license;
  return license_header;
}

function check_file_header(files_to_check, license) {
  for (let file of files_to_check) {
    const filename = file.replace(/^.*[\\\/]/, ''); // Reference: https://stackoverflow.com/a/423385
    schedule(async () => {
      const content = await danger.github.utils.fileContents(file);
      if (!content.includes("Pinterest, Inc.")) {
        const msg = "Please ensure license is correct for " + filename +":\n```" + full_license(license, filename) + "\n```";
        console.error("FAIL: " + msg);
        fail(msg);
      }  
    });
  }   
}

const new_source_license_header = hereDoc(function() {/*!
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//*/});

const modified_source_license_header = hereDoc(function() {/*!
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//*/});

// Ensure new files have proper header
if (has_added_source_files) {
  check_file_header(added_source_files, new_source_license_header);
}

// Ensure modified files have proper header
if (has_modified_source_files) {
  check_file_header(modified_source_files, modified_source_license_header);
}
