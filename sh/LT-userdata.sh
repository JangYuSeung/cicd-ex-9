#!/bin/bash
# 1. 환경 변수 설정
REGION="ap-south-2"
ACCOUNT_ID="458894893383" # AWS 계정 ID
S3_BUCKET="www.reoyuza.cloud" # S3 버킷 이름
ECR_REPO="st8/nginx" # ECR 리포지토리 이름
IMAGE_TAG="1.29.5-alpine-v1"
ECR_URL="458894893383.dkr.ecr.ap-south-2.amazonaws.com"
IMAGE_URI="${ECR_URL}/${ECR_REPO}:${IMAGE_TAG}"

# 2. Log 파일 설정
exec > >(tee -a build.log | logger -t user-data -s 2>/dev/console) 2>&1

# 3. 컨테이너와 마운트(볼륨)할 디렉토리 생성
mkdir -p /home/ec2-user/nginx/html
mkdir -p /home/ec2-user/nginx/conf.d
chown -R ec2-user:ec2-user /home/ec2-user/nginx

# 4. S3에서 HTML 파일과 Nginx 설정 파일 다운로드
aws s3 sync s3://${S3_BUCKET}/html/ /home/ec2-user/nginx/html/ --delete

# 5. ECR에 로그인
aws ecr get-login-password --region ${REGION} | \
sudo docker login --username AWS --password-stdin ${ECR_URL}

# 6. ECR에서 이미지 가져오기
sudo docker pull ${IMAGE_URI}
sudo docker stop nginx-container || true
sudo docker rm nginx-container || true

# 7. 컨테이너 실행
sudo docker run -d -p 80:80 --name nginx-container \
-v /home/ec2-user/nginx/html:/usr/share/nginx/html \
${IMAGE_URI}