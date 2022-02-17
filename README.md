# dot-net-6-aws
.NET 6 on AWS

## This covers installation on Cloud9

### Install .NET 6 from Microsoft

```bash
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install dotnet-sdk-6.0
sudo yum install aspnetcore-runtime-6.0
sudo yum install dotnet-runtime-6.0
```

### Create Hello World

[setup.sh](https://github.com/noahgift/dot-net-6-aws/blob/main/setup.sh)
```bash
dotnet new console -o hello \
    && cd hello \
    && dotnet run
```

### Running Docker in Cloud9

A good reference point is an AWS Lambda Dockerfile:
https://gallery.ecr.aws/lambda/dotnet
In order to build it, first the Cloud9 environment needs resizing.

#### Resizing

It is a good idea to both resize your environment as well as cleanup a bit.
You can refer to Bash script by AWS that allows you to easily resize Cloud9:  https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html

I have a copy of the script here:  https://github.com/noahgift/dot-net-6-aws/blob/main/utils/resize.sh.  To run it you do the following:

```bash
chmod +x resize.sh
./resize.sh 50
```

After I run this on my system I see the following output.  Notice that the mount point `/dev/nvme0n1p1` now has `41G` free.

```bash
ec2-user:~/environment/dot-net-6-aws (main) $ df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs         32G     0   32G   0% /dev
tmpfs            32G     0   32G   0% /dev/shm
tmpfs            32G  536K   32G   1% /run
tmpfs            32G     0   32G   0% /sys/fs/cgroup
/dev/nvme0n1p1   50G  9.6G   41G  20% /
tmpfs           6.3G     0  6.3G   0% /run/user/1000
tmpfs           6.3G     0  6.3G   0% /run/user/0
```

Now I can build the container.  On my Cloud9 environment I cd into the Lambda directory:

```bash
cd /home/ec2-user/environment/dot-net-6-aws/Lambda
```

Then I run `docker build -t dotnet6-lambda .`









