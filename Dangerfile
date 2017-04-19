# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"
has_source_changes = !git.modified_files.grep(/Source/).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("This is a big PR, please consider splitting it up to ease code review.") if git.lines_of_code > 500

# Changelog entries are required for changes to source files.
no_changelog_entry = !git.modified_files.include?("CHANGELOG.md")
if has_source_changes && no_changelog_entry && not_declared_trivial
  fail("Any source code changes should have an entry in CHANGELOG.md.")
end
