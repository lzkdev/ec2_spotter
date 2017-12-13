# AWS Persistant Spot Intance
Forked from https://github.com/sirishkumar/ec2_spotter

### 基于Deep Learning AMI (Ubuntu) 快速创建 EC2 竞价实例，持久保存实例数据

创建过程参考下列文章：

[https://medium.com/slavv/learning-machine-learning-on-the-cheap-persistent-aws-spot-instances-668e7294b6d8]()

中文翻译（大数据文摘）：

[https://mp.weixin.qq.com/s/XDJm8xiFUh6iRKzkcDGLZw]()

原文基于fast.ai的ami，这里修改为AWS Deep Learning AMI

The AMI Ids for the Deep Learning (Ubuntu) AMI are the following:

* us-east-1 ami-405ade3a
* us-east-2 ami-f0725c95
* us-west-2 ami-f1e73689
* eu-west-1 ami-1812bb61
* ap-southeast-2 ami-5603eb34
* ap-northeast-2 ami-0ce14662
* ap-northeast-1 ami-329c2b54

注意：Deep Learning (Ubuntu) AMI 最少需要50G EBS空间

新增 fast_ai/stop_spot.sh 自动取消竞价请求并终止竞价实例