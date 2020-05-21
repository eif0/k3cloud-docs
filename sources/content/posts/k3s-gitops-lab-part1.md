---
title: "k3s GitOps Lab | Part 1: Cluster Bootstraping + API PoC Deployment"
date: 2020-05-21T16:54:51+01:00
draft: false
showthedate: true
categories: ["k3s", "civo"]

---
This article covers:
- Bootstraping a new k3s cluster from scratch
	+ creating a free cluster using civo's #kube100
- Checking the cluster state
- Deploy a PoC test API using manifest files (.yaml)
- General testing
<!--more-->


### Kubernetes GitOps Series:
- [k3s GitOps Lab | Part 1: Cluster Bootstraping + API PoC Deployment](/posts/k3s-gitops-lab-part1/)
- k3s GitOps Lab | Part 2: k3s + GitOps using ArgoCD
- k3s GitOps Lab | Part 3: Deploying Custom Builds
   
# Requirements
- A kubernetes (k3s/k8s) __cluster__.  
     For this lab's purpose there's no diff between using k3s and k8s. 
    - Hint: you can apply for civo's [#kube100](https://www.civo.com/kube100) to get some free credit in order to test their amazing k3s managed solution. To make this guide easily reproducible for everyone this is what we're going to use on the step-by-step guide.
- `kubectl` installed.
- civo's CLI tool (`civo`) installed. If you're not using civo's #kube100 clusters you can skip this.

#### Nice-To-Have's
- A __custom domain name__ pointing to our cluster.  
 You can also use the fqdn provided by civo when we spin up the cluster, although having a custom domain name won't make any diff config/setup-wise, it's great to have a specific DNS for the cluster, in order to mimic real-world scenarios.
    - Hint: If you don't have one, you can register a free DNS using [Freenom](https://freenom.com), this is what I'm going to use to follow this series.
- __kubectx__ + __kubens__ installed in order to make it easy to switch contexts.  
  These tools are not mandatory but are going to be super helpful to have at hand for the following howtos where we will have different environments (prod + test) managed by our GitOps pipelines.

# Cluster Setup
> You can skip this section altogether if you're not using civo's k3s.  
>- Important: If you bring your own Cluster, remember to install Traefik, cert-manager and metrics-server if you wanna follow this step-by-step guide and reproduce each step.
1. Get your civo APIKEY via the webUI ([link](https://www.civo.com/account/security))
2. Add your APIKEY to civo's CLI tool  
    Hint: You can change the APIKEY name (`k3cloud`) if you feel like it
    ```sh
    $ civo apikey add k3cloud <your-api-secret>
    ```
    You can also check your current apikey, running:
    ```sh
    $ civo apikey list
    ```
    Once we have civo's CLI up and running, we can proceed to bootstrap our new cluster.  
  3. Create a new cluster with Traefik and metrics-server installed.  
  In addition we save + switch contexts to use the new cluster  

      Hints:
        - You can change the cluster name (`k3cloud`) if you feel like it.
        - You can also bootstrap the cluster with just a couple keystrokes using civo's management webUI, both `metrics-server` and `Traefik` are selected to be installed by default when using this method. 

      ```sh
      $ civo k3s create k3cloud --size=g2.medium --nodes=3 --applications=Traefik,metrics-server --wait --save --switch
      ```

      Once the cluster is created, you should get an output similar to:

      ```
      >   Building new Kubernetes cluster k3cloud: Done
      >    Created Kubernetes cluster k3cloud in 02 min 21 sec
      >    Merged config into ~/.kube/config and switched context to k3cloud
      ```
      Total cluster creation time is around 2-3min.  

      You can check which resources are currently running in the cluster.  
      Ideally you should wait for all their states to be ok before proceeding, but it's not mandatory.
      - To check the nodes status:
      ```sh
      $ kubectl get no

      NAME               STATUS   ROLES    AGE     VERSION
      kube-master-40e4   Ready    master   3h15m   v1.16.3-k3s.2
      kube-node-3daf     Ready    <none>   3h15m   v1.16.3-k3s.2
      kube-node-715c     Ready    <none>   3h15m   v1.16.3-k3s.2

      ```
  - To check the status of PODs and Deployments:
      ```sh
      $ kubectl get po,deploy -A

      NAMESPACE     NAME                                          READY   STATUS      RESTARTS   AGE
      kube-system   pod/metrics-server-6d684c7b5-4lndf            1/1     Running     0          5m4s
      kube-system   pod/local-path-provisioner-58fb86bdfd-6k5v7   1/1     Running     0          5m4s
      kube-system   pod/helm-install-traefik-zpsw2                0/1     Completed   0          5m4s
      kube-system   pod/svclb-traefik-vkw7b                       3/3     Running     0          4m23s
      kube-system   pod/svclb-traefik-f6pq9                       3/3     Running     0          4m23s
      kube-system   pod/svclb-traefik-cbptp                       3/3     Running     0          4m23s
      kube-system   pod/coredns-d798c9dd-l8q8n                    1/1     Running     0          5m4s
      kube-system   pod/traefik-65bccdc4bd-l45qk                  1/1     Running     0          4m23s
      
      NAMESPACE     NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
      kube-system   deployment.apps/metrics-server           1/1     1            1           5m16s
      kube-system   deployment.apps/local-path-provisioner   1/1     1            1           5m16s
      kube-system   deployment.apps/coredns                  1/1     1            1           5m16s
      kube-system   deployment.apps/traefik                  1/1     1            1           4m23s
              
      ```

4. Install `cert-manager`  
    For now we're going to deploy `cert-manager` using civo's CLI `applications` param.  
    To avoid vendor lock-in as much as possible, in the future we'll migrate this setup to deploy cert-manager using both helm v3 (not available by default in civo's k3s clusters) and I'll also cover how to deploy it the kubernetes way, using manifest (.yaml) resources definitions.

    In order to deploy cert-manager via civo's CLI, run:
    ```sh
    $ civo applications add cert-manager
    ```
    If you wanna check which other applications you have at your disposal, run:
    ```
    $ civo applications list
    ```
    At the time of this writting, the available apps are:
    ```sh
    +----------------------+-------------+--------------+-----------------+--------------+
    | Name                 | Version     | Category     | Plans           | Dependencies |
    +----------------------+-------------+--------------+-----------------+--------------+
    | cert-manager         | v0.11.0     | architecture | Not applicable  | Helm         |
    | Helm                 | 2.14.3      | management   | Not applicable  |              |
    | Jenkins              | 2.190.1     | ci_cd        | 5GB, 10GB, 20GB | Longhorn     |
    | KubeDB               | v0.12.0     | database     | Not applicable  | Longhorn     |
    | Kubeless             | 1.0.5       | architecture | Not applicable  |              |
    | kubernetes-dashboard | v2.0.0-rc7  | management   | Not applicable  |              |
    | Linkerd              | 2.5.0       | architecture | Not applicable  |              |
    | Longhorn             | 0.7.0       | storage      | Not applicable  |              |
    | Maesh                | Latest      | architecture | Not applicable  | Helm         |
    | MariaDB              | 10.4.7      | database     | 5GB, 10GB, 20GB | Longhorn     |
    | metrics-server       | (default)   | architecture | Not applicable  |              |
    | MinIO                | 2019-08-29  | storage      | 5GB, 10GB, 20GB | Longhorn     |
    | MongoDB              | 4.2.0       | database     | 5GB, 10GB, 20GB | Longhorn     |
    | OpenFaaS             | 0.18.0      | architecture | Not applicable  | Helm         |
    | Portainer            | beta        | management   | Not applicable  |              |
    | PostgreSQL           | 11.5        | database     | 5GB, 10GB, 20GB | Longhorn     |
    | prometheus-operator  | 0.35.0      | monitoring   | Not applicable  |              |
    | Rancher              | v2.3.0      | management   | Not applicable  |              |
    | Redis                | 3.2         | database     | Not applicable  |              |
    | Selenium             | 3.141.59-r1 | ci_cd        | Not applicable  |              |
    | Traefik              | (default)   | architecture | Not applicable  |              |
    +----------------------+-------------+--------------+-----------------+--------------+
    
    ```

    To avoid possible issues in the following steps, wait for all cert-manager resources to be up and in a ok state. To check, run:
    ```
    watch -n1 "kubectl get all -n cert-manager"
    ```
    Once the all components are in an OK state, you should see smth similar to:
    ```
    NAME                                           READY   STATUS    RESTARTS   AGE
    pod/cert-manager-55c44f98f-mqsr8               1/1     Running   0          9m57s
    pod/cert-manager-cainjector-576978ffc8-kmxvb   1/1     Running   0          9m57s
    pod/cert-manager-webhook-c67fbc858-6h9rd       1/1     Running   1          9m57s
    
    NAME                           TYPE        CLUSTER-IP        EXTERNAL-IP   PORT(S)    AGE
    service/cert-manager           ClusterIP   192.168.182.200   <none>        9402/TCP   9m57s
    service/cert-manager-webhook   ClusterIP   192.168.154.29    <none>        443/TCP    9m57s
    
    NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/cert-manager              1/1     1            1           9m57s
    deployment.apps/cert-manager-cainjector   1/1     1            1           9m57s
    deployment.apps/cert-manager-webhook      1/1     1            1           9m57s
    
    NAME                                                 DESIRED   CURRENT   READY   AGE
    replicaset.apps/cert-manager-55c44f98f               1         1         1       9m57s
    replicaset.apps/cert-manager-cainjector-576978ffc8   1         1         1       9m57s
    replicaset.apps/cert-manager-webhook-c67fbc858       1         1         1       9m57s
        
    ```  



# Deploying a PoC using manifest (.yaml) files
1. Clone k3cloud's repo and chgdir to FOAAS's sample deployment
    ```sh
    $ git clone https://github.com/k3cloud/k3cloud.git
    $ cd k3cloud/samples/foaas
    ```
2. Review and customize FOAAS API manifest files  

    Although you can change and update any part you want, only mandatory requisite is to update the ingress declaration manifest, as you will need to update the DNS name to your own.
    ```sh
    $ vim foaas-ingress.yaml
    ```
    After updating both iterations of the `host` key (replacing the `YOUR.CUSTOM.DOMAIN` value to match your custom domain), your `foaas-ingress.yaml` should look similar to:
    ```
        apiVersion: extensions/v1beta1
        kind: Ingress
        metadata:
          name: foaas-sample-ingress
          annotations:
            cert-manager.io/issuer: foaas-sample-letsencrypt
            kubernetes.io/ingress.class: "traefik"
        spec:
          tls:
          - hosts:
            - foaas.sample.YOUR.CUSTOM.DOMAIN
            secretName: foaas-sample-secret
          rules:
          - host: foaas.sample.YOUR.CUSTOM.DOMAIN
            http:
              paths:
              - path: /
                backend:
                  serviceName: foaas-sample-svc
                  servicePort: 80
        
        ```    
3. Update your DNS reccords  
Your DNS reccords for `foaas.sample.YOUR.CUSTOM.DOMAIN` should point to your Cluster endpoint, you can check your cluster specs via the CLI, running:
    ```sh
    $ civo k3s show k3cloud
    ```
    (Of course, replace `k3cloud` for your cluster name)

    If you followed all steps up to now, your output should looks similar to:
    ```
                    ID : 8bcc05ef-5f90-4cf9-b31c-7075ff6ed983
                  Name : k3cloud
              # Nodes : 3
                  Size : g2.medium
                Status : ACTIVE
              Version : 1.0.0
          API Endpoint : https://185.136.235.106:6443
          DNS A record : 8bcc05ef-5f90-4cf9-b31c-7075ff6ed983.k8s.civo.com
                        *.8bcc05ef-5f90-4cf9-b31c-7075ff6ed983.k8s.civo.com

    Nodes:
    +------------------+-----------------+--------+
    | Name             | IP              | Status |
    +------------------+-----------------+--------+
    | kube-master-40e4 | 185.136.235.106 | ACTIVE |
    | kube-node-3daf   |                 | ACTIVE |
    | kube-node-715c   |                 | ACTIVE |
    +------------------+-----------------+--------+

    Installed marketplace applications:
    +----------------+-----------+-----------+--------------+
    | Name           | Version   | Installed | Category     |
    +----------------+-----------+-----------+--------------+
    | Traefik        | (default) | Yes       | architecture |
    | Helm           | 2.14.3    | Yes       | management   |
    | metrics-server | (default) | Yes       | architecture |
    | cert-manager   | v0.11.0   | Yes       | architecture |
    +----------------+-----------+-----------+--------------+



    ```
4. Verifying DNS reccords:
    ```sh
    $ dig +short @9.9.9.9 foaas.sample.YOUR.CUSTOM.DOMAIN
    ```
    In my example, we can confirm that it resolves to my current cluster IP, which is the expected outcome once the DNS are propaggated:
    ```sh
    $ dig +short @9.9.9.9 foaas.sample.k3cloud.gq
    
    185.136.235.106
    ```
    HINT: At this point, if you wanna avoid using a custom DNS name, you have a couple options:
    - Either use Civo's fqdn (smth in the likes of: `8bcc05ef-5f90-4cf9-b31c-7075ff6ed983.k8s.civo.com` -which is my k3cloud.gq cluster fqdn-)
    - Use the local resolver (via `systemd-resolve --status`, updating `/etc/hosts` or any other valid method, depending on your distro/setup)

    However, even if we can skip the custom DNS thingy, having a custom domain name is the best option in order to have an env similar to real-world scenarios.
    
    On the bright side, as stated before, you can use Freenom.com in order to register a free domain name to play around with your shiny new cluster.



5. Deploy our PoC, the FOAAS API (Finally!)
    ```
    $ kubectl apply -f samples/fooas/
        
        deployment.apps/foaas-sample-deploy created
        ingress.extensions/foaas-sample-ingress created
        issuer.cert-manager.io/foaas-sample-letsencrypt created
        service/foaas-sample-svc created

    ```
    If you didn't change it, this sample/PoC API is deployed in the default namespace, we can check the status of our recently applied manifest running:
    ```
    $ kubectl get po,svc,cert,ingress
    ```

    Which -if all went ok- should return something similar to:
    ```
    NAME                                       READY   STATUS    RESTARTS   AGE
    pod/foaas-sample-deploy-59b9c7d76f-g4rjj   1/1     Running   0          3m43s

    NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
    service/kubernetes         ClusterIP   192.168.128.1    <none>        443/TCP   64m
    service/foaas-sample-svc   ClusterIP   192.168.198.98   <none>        80/TCP    3m43s

    NAME                                              READY   SECRET                AGE
    certificate.cert-manager.io/foaas-sample-secret   True    foaas-sample-secret   3m43s

    NAME                                      HOSTS                     ADDRESS           PORTS     AGE
    ingress.extensions/foaas-sample-ingress   foaas.sample.k3cloud.gq   185.136.235.106   80, 443   3m44s

    ```
    Here we can verify that `svc`, `deployment` and `pods` are ok, and we can also see that the `ingress` is listening in our __custom domain__ (_foaas.sample.k3cloud.gq_), and also the LetsEncrypt SSL `cert` is valid and has been applied.

6. Test your app:
    ```
    $ curl  -H 'Accept: text/plain'  foaas.sample.k3cloud.gq/rockstar/k3s/renato

        "k3s, you're a fucking Rock Star!" -renato
    ```
            

    Side notes:
    - In addition to interfacing with the API via curl/wget/whatever, you can check the valid parameters and documentation browsing to https://foaas.sample.k3cloud.gq.
    (Once again, remember to run the tests using your newly created custom domain).
    - As you can see in `foaas-sample-deploy.yaml` the deployed FOAAS image is a custom build available in dockerhub.com/eif0/foaas, this is a 100% functional build I run with extra configs and settings, but feel free to use the original repo and build your own image if you prefer. More on how to manage pipelines and deploy your custom images to k3s in future articles.



