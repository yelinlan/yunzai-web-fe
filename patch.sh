#!/bin/bash
#把文件复制到Miao崽目录
MiaoName=$1
PROJECT_PATH=$PWD
MiaoPath=$PROJECT_PATH/$MiaoName

#Miaoweb打包
cd $PROJECT_PATH/Miao-Web
pnpm i
pnpm build
#复制打包好的网页端到Miao崽
cp -r $PROJECT_PATH/Miao-Web/dist $MiaoPath/web-data

#复制配置文件
cd $PROJECT_PATH
cp $PROJECT_PATH/patch/template/redis.yaml $MiaoPath/config/config/redis.yaml

cp $MiaoPath/config/default_config/other.yaml $MiaoPath/config/config/other.yaml
sed -i 's/masterQQ:/masterQQ: "805475874"/g' $MiaoPath/config/config/other.yaml
sed -i 's/cfg.masterQQ.includes(Number(e.user_id))/cfg.masterQQ.includes(String(e.user_id))/g' $MiaoPath/lib/plugins/loader.js
cp $PROJECT_PATH/patch/template/server.js $MiaoPath/lib/tools/server.js
cp $PROJECT_PATH/patch/template/api.rest $MiaoPath/lib/tools/api.rest

cp $MiaoPath/lib/config/init.js $MiaoPath/lib/config/init.js.backup
sed -i 's/await createQQ()/\/\/await createQQ()/g' $MiaoPath/lib/config/init.js
cp $PROJECT_PATH/patch/template/config.json $MiaoPath/web-data/config.json

#Miao崽装依赖
cd $MiaoPath
pnpm i
pnpm add image-size fastify @fastify/static @fastify/cors @fastify/basic-auth uuid -w
if [ ! -d ./data  ];then
  mkdir ./data
else
  echo dir exist
fi

#启动
node $MiaoPath/lib/tools/server.js
#ip:8080
