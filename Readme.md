## GVM Dockerfile (NO UI)

#### Build the GVM container using this Dockerfile

`docker build -t trolleye/gvm:20.8.2 .`


#### Or just pull from dockerhub.

`docker pull trolleye/gvm:20.8.2`


#### Run the GVM container with 2222 open for SSH and delete when done

`docker run --rm -p 2222:22 -it trolleye/gvm:20.8.2`
