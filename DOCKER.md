## Docker commands

Build image
```shell
docker build -t fc0/esp-dev-ssh .
```

Export image to file
```shell
docker save -o ./esp-dev-ssh.tar fc0/esp-dev-ssh:latest
```

Export image to file compressed
```shell
docker save fc0/esp-dev-ssh:latest | gzip > ./esp-dev-ssh.tar.gz
```

Load image
```shell
docker load < ./esp-dev-ssh.tar.gz
```

Connect to the image as root
```shell
docker exec --user root -it espdevssh env TERM=xterm sh -l
```

Remove unused images
```shell
docker image prune
```

List volumes
```shell
docker volume ls
```

Remove volume
```shell
docker volume rm <volume_name>
```