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

[setup script](https://github.com/noahgift/dot-net-6-aws/blob/main/setup.sh)
```bash
dotnet new console -o hello \
    && cd hello \
    && dotnet run
```
