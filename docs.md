# release flow

goals:

- sd image hosted on releases on github repo
    - takes around 40 minutes to create an sd image so we will have to use a self-hosted github runner for this purpose
- toplevel nar file with instructions on how to flash pi from the nar file on releases
    - the nar file is around 4GB so this isnt really that feasible
- fast github workflow using cachix cache for most store paths
    - doable, however the image creation still takes the most time out of anything


TODO:

- [ ] make weekly sd image release job and force run for this week to test
- push latest toplevel build to my cachix
    - runtime vs buildtime closures -> pushed runtime closure however this isnt really that useful
- add my cachix as a binary substituter in the flake


i think that the best course of action would be to cache the buildtime artifacts of the toplevel in my cachix cache and do this on each of the pushes to the repo
-> do a weekly job on the github workflow that pushes that weeks sdimage from the hytech_nixos, dont do on every push to master

```
nix-store -qR --include-outputs $(nix-store -qd ./result) \
  | grep -v '\.drv$' \
  | cachix push mycache
```