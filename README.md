# dot-net-6-aws-containers
.NET 6 on AWS for Containers using Cloud9

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
https://gallery.ecr.aws/lambda/dotnet.  This contains instructions on how to build AWS Lambda that targets the .NET 6 runtime.
Another great resource is the official .NET 6 support on AWS:  https://github.com/aws-samples/aws-net-guides/tree/master/RuntimeSupport/dotnet6

In order to build containers, I first the Cloud9 environment needs resizing. Let's tackle that next.

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

Next let's build an AWS Lambda container with .NET 6.

#### Containerized.NET 6 on Lambda 

To build a Lambda container on my Cloud9 environment I cd into the Lambda directory:

```bash
cd /home/ec2-user/environment/dot-net-6-aws/Lambda
```
Then I run `docker build -t dotnet6-lambda:latest .`

#### Containerized .NET 6 on API

Another way to go is to build a Microservice that deploys with a container service like AWS ECS or AWS App Runner.  Both methods offer an efficient way to deploy an API with minimal effort.
To get started first create a new web API project in Cloud9.

```bash
dotnet new web -n WebServiceAWS
```

Running this in my Cloud9 environment generates the following output:

```bash
ec2-user:~/environment/dot-net-6-aws (main) $ dotnet new web -n WebServiceAWS
The template "ASP.NET Core Empty" was created successfully.

Processing post-creation actions...
Running 'dotnet restore' on /home/ec2-user/environment/dot-net-6-aws/WebServiceAWS/WebServiceAWS.csproj...
  Determining projects to restore...
  Restored /home/ec2-user/environment/dot-net-6-aws/WebServiceAWS/WebServiceAWS.csproj (in 88 ms).
Restore succeeded.
```

Let's change the default code a bit by adding slightly fancier route.  You can find more information about Routing in ASP.NET Core here:
https://docs.microsoft.com/en-us/aspnet/core/fundamentals/routing?view=aspnetcore-6.0. Note in the following example how similar this code looks to other high level languages like Node, Ruby, Python or Swift.

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Home Page");
app.MapGet("/hello/{name:alpha}", (string name) => $"Hello {name}!");
app.Run();
```

Now you can run this code by changing into the directory using `dotnet run`

```bash
cd WebServiceAWS && dotnet run
```

The output looks something like this in AWS Cloud9.  Note how cool it is that you can see the full content root path showing for your Cloud9 Environment making it easy to host multiple projects and switch back and forth between working on them.

```bash
ec2-user:~/environment/dot-net-6-aws (main) $ cd WebServiceAWS && dotnet run
Building...
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:7117
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5262
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
      Content root path: /home/ec2-user/environment/dot-net-6-aws/WebServiceAWS/
```

You can see the output below, note how cool it is to toggle terminals side by side along side the code.

![5-4-cloud9-aspnet](https://user-images.githubusercontent.com/58792/154587840-d892150d-9b11-4c42-aee3-7fb9400ce689.png)

##### Containerize the Project

Now let's convert our project to using a container so it can be deployed to services that support containers.
To do this create a `Dockerfile` in the project folder.

```bash
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["WebServiceAWS.csproj", "./"]
RUN dotnet restore "WebServiceAWS.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "WebServiceAWS.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "WebServiceAWS.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "WebServiceAWS.dll"]
```

Now build this container.

`docker build . -t web-service-dotnet:latest`

You can take a look at the container by using `docker image ls`.
The output should look something like this.

`web-service-dotnet  latest  3c191e7643d5   38 seconds ago   208MB`

To run it do the following:

`docker run -p 8080:8080 web-service-dotnet:latest`

The output should like follows:

```bash
 listening on: {address}"}}
{"EventId":0,"LogLevel":"Information","Category":"Microsoft.Hosting.Lifetime","Message":"Application started. Press Ctrl\u002BC to shut down.","State":{"Message":"Application started. Press Ctrl\u002BC to shut down.","{OriginalFormat}":"Application started. Press Ctrl\u002BC to shut down."}}
{"EventId":0,"LogLevel":"Information","Category":"Microsoft.Hosting.Lifetime","Message":"Hosting environment: Production","State":{"Message":"Hosting environment: Production","envName":"Production","{OriginalFormat}":"Hosting environment: {envName}"}}
{"EventId":0,"LogLevel":"Information","Category":"Microsoft.Hosting.Lifetime","Message":"Content root path: /app/","State":{"Message":"Content root path: /app/","contentRoot":"/app/","{OriginalFormat}":"Content root path: {contentRoot}"}}
```

Now invoke it via curl: `curl http://localhost:8080/hello/aws`




