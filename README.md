## Development in a Container

It takes some time and effort to configure ESP-IDF and CLion to develop projects for ESP32.
And if you need to switch to another PC or operating system you will need to go through all the configuration steps again.

To solve this it is possible to utilize the Remote Development feature from the CLion IDE and create a Docker image that could have all required software preconfigured.
Even if you are not using CLion you can use such image to build and debug your projects with a command line tools.

For remote development we will use open-ssh server, for building the UI nodejs and esp-idf toolchain for building and flashing ESP32 images.

How to configure ssh in docker is described in [this](https://www.techrepublic.com/article/deploy-docker-container-ssh-access/) article. 
Official Espressif [Dockerfile](https://github.com/espressif/esp-idf/blob/release/v4.4/tools/docker/Dockerfile) could help us to get building environment in Docker. 

So, to start using the docker image you need to build it, run it and connect to it with CLion.

### Build and run Docker image

Prerequisites:
- you have .ssh folder with your keys in the home folder
- your device is attached to the usb port of the host machine
If these conditions are not met just update docker-compose file by your needs before running the image.

1. Clone the repository
   - `git clone git clone git@github.com:devices-fc0-org/esp-dev-ssh.git`
2. build docker image
   - `docker build -t fc0/esp-dev-ssh .` 
3. start container with docker-compose
   - `docker-compose up -d` 

Now you should be able to connect with ssh to your container.
```shell
ssh sshuser@192.168.3.254 -p 2223
``` 
where 192.168.3.254 is your host ip.
Use password `devuserPass`.

Update permissions to mounted volumes (this step should be done only once)
```shell
sudo chown sshuser:sshgroup /home/sshuser/src
sudo chown sshuser:sshgroup /home/sshuser/.ssh
sudo chown sshuser:sshgroup /home/sshuser/.cache
sudo chown sshuser:sshgroup /home/sshuser/.git
sudo chown sshuser:sshgroup /dev//dev/ttyUSB0
```

Configure your git username and email (this step could be skipped if you are not going to push code to your repository)
```shell
git config --global user.name "Your Name"
git config --global user.email "youremail@yourdomain.com"
```

Now you can either clone your project into ~/src folder or copy one of the examples from the esp-idf
```shell
cp -r /opt/esp/idf/examples/get-started/hello_world ~/src
```

### Connect to the Docker image with CLion
1. Run CLion and choose _Remote Development_ -> _SSH_ 
![SSH](img/remote-dev.png)
2. Click _New Connection_ and fill in your connection parameters
![Сonnection Parameters](img/params.png)
3. Click the _Check Connection and Continue_ button
4. Then choose IDE version and Project folder. IDE version should be the same version that you are running locally.
![img.png](img/project.png)
5. Click _Start IDE and Connect_
6. In the Open Project Wizard ignore the warning and click _Next_ and then _Finish_
![img.png](img/open-project.png)
7. If everything went well you should see a \[Finished\] record in the CMake tab.
![img.png](img/ide.png)
8. Use Run configurations dropdown to choose the cmake target and a build icon to execute them.

