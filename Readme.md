## GVM Dockerfile (NO UI)

#### Build the GVM container using this Dockerfile

`docker build -t trolleye/gvm:latest .`

#### Run the GVM container with 2222 open for SSH and delete when done

`docker run --rm -p 2222:22 -it trolleye/gvm:latest`