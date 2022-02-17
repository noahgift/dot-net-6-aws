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

```bash
dotnet new console -o hello \
    && cd hello \
    && dotnet run
```

### Running in Docker

A good reference point is :
https://github.com/aws/aws-lambda-dotnet/blob/master/LambdaRuntimeDockerfiles/Images/net6/amd64/Dockerfile