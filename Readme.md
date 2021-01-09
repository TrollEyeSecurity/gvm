## OpenVas Dockerfile (NO UI)

#### Build the OpenVas container using this Dockerfile

`docker build -t trolleye/openvas:latest .`

#### Run the OpenVas container with 2222 open for SSH and delete when done

`docker run --rm -p 2222:22 -it trolleye/openvas:latest`