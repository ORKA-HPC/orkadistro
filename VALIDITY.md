# Validity Checklist for Docker Images

- [ ] image-type = dev: 
  - [ ] only one rose version built.
- [ ] image-type = dev-edg: two rose version built /usr/rose{,-git}
- [ ] image-type = prod: TODO
- [ ] for all image-types: no EDG sources in image
- [ ] check if orkaevolution can be built against the installed ROSE libraries
- [ ] check if orkaevolution test ist runnable
