# advbinfmt from RootWyrm

This is a 'more advanced' binfmt solution for Docker buildx. Where by 'more advanced' I mean 'it's built with a much newer or more stable qemu.' 

As a result, it generally tends to be faster. This is not a bad thing.

Like it? Love it? Saved your project? Show me some love. 
* [Sponsor on GitHub](https://github.com/sponsors/rootwyrm)
* [Sponsor on Patreon](https://www.patreon.com/rootwyrm)

![(Docker) advbinfmt](https://github.com/rootwyrm/rootcore/workflows/(Docker)%20advbinfmt/badge.svg?branch=master)![Docker Pulls](https://img.shields.io/docker/pulls/rootwyrm/advbinfmt)![Docker Image Size (tag)](https://img.shields.io/docker/image-size/rootwyrm/advbinfmt/4.2.1?label=4.2.1&style=flat-square)![Docker Image Size (tag)](https://img.shields.io/docker/image-size/rootwyrm/advbinfmt/5.1.0?label=5.1.0&style=flat-square)

# Using it for your buildx
It's really simple. Pick a version from the list below.

* 4.2.1 - June 25, 2020
  `docker run --rm --privileged docker.io/rootwyrm/advbinfmt:4.2.1`
* 5.1.0 - August 11, 2020 
  `docker run --rm --privileged docker.io/rootwyrm/advbinfmt:5.1.0`

# Using it in a GitHub Workflow with buildx
Slightly more complicated, but not really.

```
jobs:
  yourjob:
    ## You can't use buildx on -latest, always use -20.04 or above
    runs-on: ubuntu-20.04
    env:
	  QEMU: 5.1.0
    steps:
    - name: Set up binfmt
      id: binfmt
      run: |
        docker run --rm --privileged rootwyrm/advbinfmt:${QEMU}
        docker buildx create --name action --use
    - name: The rest of your steps
      ...
```

If for some insane reason you're actually testing QEMU versions themselves...

```
jobs:
  yourjob:
    ## You can't use buildx on -latest, always use -20.04 or above
    runs-on: ubuntu-20.04
    strategy:
      matrix:
        qemu: [ "4.2.1", "5.1.0" ]
    steps:
    - name: Set up binfmt
      id: binfmt
      run: |
        docker run --rm --privileged rootwyrm/advbinfmt:${{ matrix.qemu }}
        docker buildx create --name action --use
    - name: The rest of your steps
      ...
```
