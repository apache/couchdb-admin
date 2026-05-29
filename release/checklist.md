# CouchDB Release Checklist

This document outlines the steps needed for a CouchDB release to happen. This is
_after_ the ASF vote procedure as finished and a release tarball is available.

We use this checklist to make sure we have a smooth release experience and that
all artefacts are available to all downstream users.

## Checklist

- [ ] The ASF vote procedure has finished and a release tarball is available.
  - [ ] This includes a release tag with an updated “What’s New” document for
        the new release version.

### Prepare Artefacts
- [ ] Upload tarball to dist.a.o.
- [ ] Coordinate so macOS and Windows binaries are built, tested and uploaded to CDN. (Jan)
- [ ] Build and test .deb and .rpm packages, upload to jfrog.
- [ ] Build and test new Docker image, update `apache/couchdb-docker`.
  - [ ] Open PR on `docker/official-images`, have notified ASF maintainers `+1`.
  - [ ] Wait for Docker PR to be merged and images available at `apache/couchdb` on Docker Hub.

### Prepare Release Announcements
- [ ] Write Release Announcement Mail (see template in `../email`)
- [ ] Copy & format Release Announcement Mail into blog.couchdb.org.
- [ ] Write Social Media Messages (Mastodon, Bluesky).

### Finish Release
- [ ] On ReadTheDocs, set the latest tag to the newly released version tag.
- [ ] Coordinate so macOS and Windows binaries are available on `neighbourhood.ie`. (Jan)
- [ ] Merge couchdb.apache.org PR.
- [ ] Send Release Announcement Mail.
- [ ] Publish Announcement Blog Post.
- [ ] Send Social Media Messages (Mastodon, Bluesky).
- [ ] Update Slack `#general` channel title to new version.
- [ ] Send Slack message to `#general` and `#pouchdb` pointing to the blog post.

### Done

Celebrate :)
