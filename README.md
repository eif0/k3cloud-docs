#### Hugo source files
```sources/```

#### Build version definition
```.env```
this is used for:
- the docker image tag @ dockerhub (used in the gh action in .github/workflows)
- the displayed version in http://docs.k3lab.gq/about (via sed in Dockerfile)
- the .env file in the repo, to reference which img version (and deployment) this version of the code generated.


#### Image build instructions that use hugo's /public + nginx:
Dockerfile
