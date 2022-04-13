install:
	sudo rpm -Uvh --force https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
	sudo yum -y install dotnet-sdk-6.0
	sudo yum -y install aspnetcore-runtime-6.0
	sudo yum -y install dotnet-runtime-6.0
deploy:
	cd WebServiceAWS && aws ecr get-login-password --region us-east-1\
	| docker login --username AWS \
	--password-stdin 561744971673.dkr.ecr.us-east-1.amazonaws.com && \
	docker build -t web-service-dotnet . && \
	docker tag web-service-dotnet:latest \
	561744971673.dkr.ecr.us-east-1.amazonaws.com/web-service-dotnet:latest && \
	docker push \
	561744971673.dkr.ecr.us-east-1.amazonaws.com/web-service-dotnet:latest
all:  install deploy
