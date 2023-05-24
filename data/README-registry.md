# README: RCT Registry data and outputs

This directory contains outputs from an analysis of the AEA RCT Registry. Source code and original outputs are available at [https://github.com/J-PAL/AEA_registryanalysis](https://github.com/J-PAL/AEA_registryanalysis).

We synchronize using a download, instead of a "git submodule", because Overleaf does not like such structures. Thus, this must be manually done on an intermediate system.

```{bash}
./sync-registry-git.sh
```

Should do the trick. ONLY works once public!