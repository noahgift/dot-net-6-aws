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

![5-5-containerized-dotnet](https://user-images.githubusercontent.com/58792/154597821-85538b62-c1ba-486a-9250-9c43d3600be8.png)

##### ECR

![5-6-ecr](https://user-images.githubusercontent.com/58792/154720964-0e7de542-b640-4ce1-b78a-c0fd39a35aaf.png)

Create a new ECR Repo:

![5-6-2-ecr-create](https://user-images.githubusercontent.com/58792/154752026-4ec362f8-c4d0-436f-9759-d9eb2ae928d8.png)

Next click on the repo to find the push commands.

![5-6-3-ecr-push](https://user-images.githubusercontent.com/58792/154752107-56b9bf03-d1c1-44b2-b906-091aa7f0841f.png)

Now checkout the image:


![5-6-4-ecr-image](https://user-images.githubusercontent.com/58792/154753326-fb3b0b4d-23fe-4e40-b447-e5aba40ef5b0.png)

##### App Runner

<img width="976" alt="5-7-app-runner" src="https://user-images.githubusercontent.com/58792/154722019-87efa041-ea03-40c4-a166-73122fc239a3.png">

Select container:

![5-7-2-app-runner-container](https://user-images.githubusercontent.com/58792/154760740-b62da26a-7ec0-4a11-9202-93d0866ed281.png)

Select Deploy process:

![5-7-3-app-runner-deploy](https://user-images.githubusercontent.com/58792/154760762-38d0237c-6562-407b-93d4-599e603c0d03.png)

Select ports:

![5-7-4-app-runner-ports](https://user-images.githubusercontent.com/58792/154760785-06dcf94c-55d2-445d-b83d-904ddfbd4be6.png)

Select service:

![5-7-5-app-runner-service](https://user-images.githubusercontent.com/58792/154760825-7d49948f-16ec-4d26-a33c-493511c39afa.png)

Curl API:

![5-7-6-app-runner-curl](https://user-images.githubusercontent.com/58792/154760885-45a7dc18-6658-4e27-b5bb-f1a3a8d6b3fb.png)

Review Architecture:

![5-7-7-app-runner-architecture](https://user-images.githubusercontent.com/58792/154760904-887b8c28-1787-4e21-b015-8495ba0d3ee1.png)



##### AWS Copilot CLI


<img width="1218" alt="5-8-co-pilot" src="https://user-images.githubusercontent.com/58792/154723375-76907b87-9af2-4b25-8ac6-9fc63ea20ffb.png">

## Reference

* [Watch walkthrough on YouTube](https://www.youtube.com/watch?v=nUAQHzz_t9k)
* [Watch walkthrough on O'Reilly](https://learning.oreilly.com/search/?query=noah%20gift&extended_publisher_data=true&highlight=true&include_assessments=false&include_case_studies=true&include_courses=true&include_playlists=true&include_collections=true&include_notebooks=true&include_sandboxes=true&include_scenarios=true&is_academic_institution_account=false&source=user&sort=relevance&facet_json=true&json_facets=true&page=0&include_facets=true&include_practice_exams=true)




