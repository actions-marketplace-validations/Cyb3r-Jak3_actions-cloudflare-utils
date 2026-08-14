import * as semver from 'semver'
import {Inputs} from './context.js'

export interface GitHubRelease {
  tag_name: string
}

export const getRelease = async (inputs: Inputs): Promise<GitHubRelease> => {
  if (inputs.version === 'latest') {
    return getLatestRelease(inputs)
  }
  if (semver.valid(inputs.version) != null) {
    return getReleaseTag(inputs)
  }
  if (semver.validRange(inputs.version) != null) {
    return getReleaseByRange(inputs)
  }
  throw new Error(
    `Version ${inputs.version} is not a valid semver version or range`
  )
}

export const getReleaseTag = async (inputs: Inputs): Promise<GitHubRelease> => {
  const response = await inputs.github_client.rest.repos.getReleaseByTag({
    owner: 'Cyb3r-Jak3',
    repo: 'cloudflare-utils',
    tag: inputs.version
  })
  return {tag_name: response.data.tag_name}
}

export const getReleaseByRange = async (
  inputs: Inputs
): Promise<GitHubRelease> => {
  const releases = await inputs.github_client.paginate(
    inputs.github_client.rest.repos.listReleases,
    {owner: 'Cyb3r-Jak3', repo: 'cloudflare-utils'}
  )

  const tagsByVersion = new Map<string, string>()
  for (const release of releases) {
    const cleaned = semver.valid(release.tag_name.replace(/^v/, ''))
    if (cleaned != null) {
      tagsByVersion.set(cleaned, release.tag_name)
    }
  }

  const maxVersion = semver.maxSatisfying(
    [...tagsByVersion.keys()],
    inputs.version
  )
  if (maxVersion == null) {
    throw new Error(`No release found matching version range ${inputs.version}`)
  }

  return {tag_name: tagsByVersion.get(maxVersion) as string}
}

export const getLatestRelease = async (
  inputs: Inputs
): Promise<GitHubRelease> => {
  const response = await inputs.github_client.rest.repos.getLatestRelease({
    owner: 'Cyb3r-Jak3',
    repo: 'cloudflare-utils'
  })
  return {tag_name: response.data.tag_name}
}
