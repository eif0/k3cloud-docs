## Contribution, Pipelines and Deployment

Sources pushed or PRs to this repo get automatically built into static html files using hugo via the Dockerfile (1), and they get automatically pushed to [dockerhub/eif0/k3cloud-docs](https://hub.docker.com/r/eif0/k3cloud-docs/) tagging the version number defined in .env, this whole pipeline is managed via GitHub Actions (3).

By following this deployment schema, contributions, proof-reading and new content can be added to the documentation by any third party.

But... how?
1. Add your new content or modify anything under `sources/content/posts` within this repo.
2. Do a Pull Request with the changes.
3. Once the maintainers approve the PR, your new changes will be picked up by the CI/CD pipelines descibed next and will be built into Docker Image, which later on will be deployed to the respective PRD/TEST cluster.

## Configurations & Components

All sources, configs and definitions to build the repo are available within itself.

Pipeline-related configs and files:
```
.
├── Dockerfile (1)
├── .env (2)
└── .github
    └── workflows
        └── dockerimage.yml (3)
```

(1): Instructions to build the image and tag it accordingly.  
- If it was pushed to the branch:`test` then the img version tag is k3cloud-docs:x.x.x-test
- If it was pushed to the branch:`master` then the img version tag is k3cloud-docs:x.x.x  

(2): Version number declaration.  

(3): GitHub Actions manifest. The pipelines basically run 5 major steps:
- Pull the repo
- Build sources into static files
- Minor cosmetic tweaks
- Build new image to serve the new files/content using nginx
- Push new image to Dockerhub

## Workflow

### TEST pipeline
For the `test` branch, the .env file declares `VERSION="x.x.x-test"`
```
[ USER ]  ---PR/Push--->   [ REPO/branch:test ]   ---GH-Actions:test--->   [ DOCKERHUB/tag:x.x.x-test ]
```

### MASTER pipeline
For the `master` branch, the .env file declares `VERSION="x.x.x"`
```
[ USER ]  ---PR/Push--->   [ REPO/branch:master ]   ---GH-Actions:test--->   [ DOCKERHUB/tag:x.x.x ]
```


## Continuous Deployment to k3s using ArgoCD
This repo is currently deployed in accordance to the following basic workflows:

1. From (app sources) repo to Docker Image

- If the new source code changes are in the `master` branch: the new image get pushed to DockerHub (tag:x.x.x) and later declared in k3cloud's manifest file for the docs' repo deployment (prod/docs/hugo-nginx-deploy.yaml @ [k3cloud repo](https://github.com/k3cloud/k3cloud) | branch `master`).
- If the new source code changes are in the `test` branch: the new image get pushed to DockerHub (tag:x.x.x-test) and later declared in k3cloud's manifest file for the docs' repo deployment (prod/docs/hugo-nginx-deploy.yaml @ [k3cloud repo](https://github.com/k3cloud/k3cloud) | branch `test`) 

2. From Docker Image to deployment in the k3s Cluster

	When a new version is out (after the GH Action pipeline runs, when we have the new image built and pushed to DockerHub), we need to update the cluster resource definitions in order to deploy the newly built image into it.
	
	We can do it by either pushing the resource manifest changes to the k3cloud repo, or merging an external Pull Request which updates the definition files.  
	
	When changes are pushed/merged, ArgoCD (who actively monitors the repo state) picks up the changes and apply them to the cluster, in accordance to the following criteria:
	- If the changes are done in [k3cloud](https://github.com/k3cloud/k3cloud)'s `master` branch, all updated .yaml files are picked up by the ArgoCD deployment running in the PROD Cluster (which monitors only k3cloud's `master` branch).  
	All the updated resources are then applied to the PRD Cluster (currently located at https://k3cloud.gq / https://docs.k3cloud.gq)
	- If the changes are done in [k3cloud](https://github.com/k3cloud/k3cloud)'s `test` branch, all updated .yaml files are picked up by the ArgoCD deployment running in the TEST Cluster (which monitors only k3cloud's `test` branch).  
	All the updated resources are then applied to the TEST Cluster (currently located at https://k3lab.gq / https://docs.k3lab.gq)
	

## Files and Resources
##### Hugo source files:
```sources/```

##### Build version definition:
```.env```
this is used for:
- the docker image tag @ dockerhub (used in the gh action in .github/workflows)
- the displayed version in http://<host>/about (via sed in Dockerfile)
- the .env file in the repo, to reference which img version (and deployment) this version of the code generated.
- the version reference in the -deploy.yaml manifest files.


##### Image build instructions that use hugo's /public + nginx:
```Dockerfile```
