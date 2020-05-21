## Contribution, Pipelines and Deployment

Sources pushed or PR to this repo get automatically built into static html files using hugo via the Dockerfile (1), and they get pushed into [dockerhub/eif0/k3cloud-docs](https://hub.docker.com/r/eif0/k3cloud-docs/), the whole pipeline is managed via GitHub Actions (3).

All sources and reqs to build are present in the repo.
Pipeline-related configs and files:
```
.
├── Dockerfile (1)
├── .env (2)
└── .github
    └── workflows
        └── dockerimage.yml (3)
```

(1): Instructions to build the image and tag it accordingly (if it was pushed to branch:`test` then the img version tag is k3cloud-docs:x.x.x-test
(2): Version number identifier
(3): GitHub Actions declaration

## Workflow
### TEST pipeline
[Usr]   --PR/GitPush-->   [repo/branch:test]   --GH-Actions:test-->   [DockerHub/tag:x.x.x-test]
						(pull,build,push)

      .env|VERSION=x.x.x-test		



### MASTER pipeline

[Usr]   --PR/GitPush-->   [repo/branch:master]   --GH-Actions:master-->   [DockerHub/tag:x.x.x]
                                                  (pull,build,push)
  
      .env|VERSION=x.x.x

        

## Deployment to test(docs.k3lab.gq) or master(docs.k3cloud.gq)

#### Hugo source files
```sources/```

#### Build version definition
```.env```
this is used for:
- the docker image tag @ dockerhub (used in the gh action in .github/workflows)
- the displayed version in http://<host>/about (via sed in Dockerfile)
- the .env file in the repo, to reference which img version (and deployment) this version of the code generated.
- the version reference in the -deploy.yaml manifest files.


#### Image build instructions that use hugo's /public + nginx:
```Dockerfile```
