# About:
#
# This is a helper script to tag and push a new release. GitHub Actions use
# release tags to allow users to select a specific version of the action to use.
#
# See: https://github.com/actions/typescript-action#publishing-a-new-release
# See: https://github.com/actions/toolkit/blob/master/docs/action-versioning.md#recommendations
#
# This script will do the following:
#
# 1. Retrieve the latest release tag
# 2. Display the latest release tag
# 3. Prompt the user for a new release tag
# 4. Validate the new release tag
# 5. Remind user to update the version field in package.json
# 6. Tag a new release
# 7. Set 'is_major_release' variable
# 8. Point separate major release tag (e.g. v1, v2) to the new release
# 9. Push the new tags (with commits, if any) to remote
#
# Usage:
#
# scripts/release.ps1

# Exit early on any error
$ErrorActionPreference = 'Stop'

# Variables
$semverTagRegex = 'v[0-9]+\.[0-9]+\.[0-9]+$'
$semverTagGlob = 'v[0-9].[0-9].[0-9]*'
$gitRemote = 'origin'
$majorSemverTagRegex = '^(v[0-9]+)'

# 1. Retrieve the latest release tag
$latestTag = git describe --abbrev=0 --match="$semverTagGlob" 2>$null
if (-not $LASTEXITCODE -eq 0 -or -not $latestTag) {
	# There are no existing release tags
	Write-Host "No tags found (yet) - Continue to create and push your first tag"
	$latestTag = "[unknown]"
}

# 2. Display the latest release tag
Write-Host "The latest release tag is: " -NoNewline
Write-Host $latestTag -ForegroundColor Blue

# 3. Prompt the user for a new release tag
$newTag = Read-Host 'Enter a new release tag (vX.X.X format)'

# 4. Validate the new release tag
if ($newTag -match $semverTagRegex) {
	# Release tag is valid
	Write-Host "Tag: " -NoNewline
	Write-Host $newTag -ForegroundColor Blue -NoNewline
	Write-Host " is valid syntax"
} else {
	# Release tag is not in `vX.X.X` format
	Write-Host "Tag: " -NoNewline
	Write-Host $newTag -ForegroundColor Blue -NoNewline
	Write-Host " is " -NoNewline
	Write-Host "not valid" -ForegroundColor Red -NoNewline
	Write-Host " (must be in vX.X.X format)"
	exit 1
}

# 5. Remind user to update the version field in package.json
Write-Host "Make sure the version field in package.json is " -NoNewline
Write-Host $newTag -ForegroundColor Blue -NoNewline
Write-Host ". Yes? [Y/n] " -NoNewline
$yn = Read-Host

if ($yn -ne 'y' -and $yn -ne 'Y') {
	# Package.json version field is not up to date
	Write-Host "Please update the package.json version to " -NoNewline
	Write-Host $newTag -ForegroundColor Magenta -NoNewline
	Write-Host " and commit your changes"
	exit 1
}

# 6. Tag a new release
git tag -s "$newTag" --annotate --message "$newTag Release"
Write-Host "Tagged: " -NoNewline
Write-Host $newTag -ForegroundColor Green

# 7. Set 'is_major_release' variable
$newMajorReleaseTag = [regex]::Match($newTag, $majorSemverTagRegex).Groups[1].Value

if ($latestTag -eq "[unknown]") {
	# This is the first major release
	$isMajorRelease = $true
} else {
	# Compare the major version of the latest tag with the new tag
	$latestMajorReleaseTag = [regex]::Match($latestTag, $majorSemverTagRegex).Groups[1].Value

	if ($newMajorReleaseTag -ne $latestMajorReleaseTag) {
		$isMajorRelease = $true
	} else {
		$isMajorRelease = $false
	}
}

# 8. Point separate major release tag (e.g. v1, v2) to the new release
if ($isMajorRelease) {
	# Create a new major version tag and point it to this release
	git tag -s "$newMajorReleaseTag" --annotate --message "$newMajorReleaseTag Release"
	Write-Host "New major version tag: " -NoNewline
	Write-Host $newMajorReleaseTag -ForegroundColor Green
} else {
	# Update the major version tag to point it to this release
	git tag -s "$latestMajorReleaseTag" --force --annotate --message "Sync $latestMajorReleaseTag tag with $newTag"
	Write-Host "Synced " -NoNewline
	Write-Host $latestMajorReleaseTag -ForegroundColor Green -NoNewline
	Write-Host " with " -NoNewline
	Write-Host $newTag -ForegroundColor Green
}

# 9. Push the new tags (with commits, if any) to remote
git push --follow-tags

if ($isMajorRelease) {
	# New major version tag is pushed with the '--follow-tags' flags
	Write-Host "Tags: " -NoNewline
	Write-Host $newMajorReleaseTag -ForegroundColor Green -NoNewline
	Write-Host " and " -NoNewline
	Write-Host $newTag -ForegroundColor Green -NoNewline
	Write-Host " pushed to remote"
} else {
	# Force push the updated major version tag
	git push $gitRemote "$latestMajorReleaseTag" --force
	Write-Host "Tags: " -NoNewline
	Write-Host $latestMajorReleaseTag -ForegroundColor Green -NoNewline
	Write-Host " and " -NoNewline
	Write-Host $newTag -ForegroundColor Green -NoNewline
	Write-Host " pushed to remote"
}

# Completed
Write-Host "Done!" -ForegroundColor Green
