
# yunzai-web-fe
### 项目来自 https://github.com/117503445/yunzai-bot-web
### 希望 web能与QQ一起用（但是会起两个独立应用，希望可以优化为只起一个应用）
# 先看效果
### QQ
![image](https://github.com/yelinlan/yunzai-web-fe/assets/38036830/74c92895-b7af-42a1-b5d9-13c81640b84d)

### Web
![image](https://github.com/yelinlan/yunzai-web-fe/assets/38036830/935718ab-cfef-4a7f-bdf5-aedef16edeb3)

### 安装依赖 
  npm install     
  pnpm -g pnpm install
### 打包 npm run build 在dist目录
### 把包放到 服务器
# 使用nginx代理
### 安装nginx
yum install nginx
nginx -v
### 修改配置
cd /etc/nginx  
vi nginx.config
###   刷新配置，并重启
 nginx -t   
 nginx -s reload  
 service nginx restart  
#配置如下
```
user root;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        server_name  123.249.87.173;


        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {  #首页
            root   /root/Miao-Yunzai/web-data/nginx/dist; #web页面目录
            index  index.html; #转发到
        }

        location /api { #转发80端口请求数据到本地8080端口，用来调用服务器本地云崽
            root   /root/Miao-Yunzai/web-data/nginx/dist;  #web页面目录
            proxy_pass http://127.0.0.1:8080; #转发到


            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /images { #请求图片时，到指定目录去找
            alias  /root/Miao-Yunzai/web-data/images;
            autoindex on;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
```
###   输入IP：端口访问
403原因（user:root|777|selinux|）:  
https://juejin.cn/post/6978740097428488222  

# 新建目录
### 如下
/root/Miao-Yunzai/web-data/nginx/dist  
/root/Miao-Yunzai/web-data/images  

### 复制原先web的插件
cp server.js api.rest 到 /root/Miao-Yunzai/lib/tools 目录下
# 启动
### 在目录下/root/Miao-Yunzai执行命令
 node ./lib/tools/server.js  
 ![image](https://github.com/yelinlan/yunzai-web-fe/assets/38036830/0a91f8be-9e99-49fd-a6e3-61ed98e6399a)  
 ### 访问 IP
 ![image](https://github.com/yelinlan/yunzai-web-fe/assets/38036830/f9f20e44-6931-4ccf-9443-8065abcce43c)



#其他
### server.js
```
import path from 'path';
import * as fs from 'fs/promises'
import { v4 as uuidv4 } from 'uuid';

import '../config/init.js'
import PluginsLoader from '../plugins/loader.js'

import Fastify from 'fastify'
import * as fstatic from '@fastify/static'
import cors from '@fastify/cors'

import basicAuth from '@fastify/basic-auth'

fs.mkdir('./web-data/images', { recursive: true })

let multiUser = false
let users = {}

try {
    const text = await fs.readFile('./web-data/config.json');
    const cfg = JSON.parse(text);
    multiUser = cfg['multiUser']
    users = cfg['users']
    logger.info('cfg: ', cfg)
} catch (e) {
    logger.info('read config failed, error: ', e)
}


global.Bot = {}
await PluginsLoader.load()

const fastify = Fastify({
    logger: true
})

fastify.register(cors, {
    origin: true,
})

const __dirname = path.resolve();
fastify.register(fstatic, {
    root: __dirname + '/web-data',
    prefix: '/',
})


const authenticate = { realm: 'YunzaiBotWeb' }
fastify.register(basicAuth, { validate, authenticate })
function validate(username, password, req, reply, done) {
    if (!multiUser) {
        done()
    } else {
        let user = users[username]
        if (!user) {
            done(new Error("auth failed, user not found"))
        } else {
            if (user["password"] === password) {
                req.headers["qq"] = users[username]["qq"]
                done()
            } else {
                done(new Error("auth failed, wrong password"))
            }
        }
    }
}
fastify.after(() => {
    fastify.addHook('onRequest', fastify.basicAuth)


    fastify.post('/api/chat-process', async (request, reply) => {
        let qq = 805475874
        if (request.headers['qq']) {
            qq = request.headers['qq']
        }

        let prompt = request.body.prompt
        logger.info('prompt = ', prompt)
        logger.info('qq = ', qq)
        let e = {
            "test": true,
            "self_id": 10000,
            "time": 1676913595310,
            "post_type": "message",
            "message_type": "friend",
            "sub_type": "normal",
            "group_id": 826198224,
            "group_name": "测试群",
            "user_id": qq,
            "anonymous": null,
            "message": [
                {
                    "type": "text",
                    "text": prompt
                }
            ],
            "raw_message": "#uid",
            "font": "微软雅黑",
            "sender": {
                "user_id": qq,
                "nickname": "测试",
                "card": "this_is_card",
                "sex": "male",
                "age": 0,
                "area": "unknown",
                "level": 2,
                "role": "owner",
                "title": ""
            },
            "group": {
                "mute_left": 0
            },
            "friend": {},
            "message_id": "JzHU0DACliIAAAD3RzTh1WBOIC48"
        }

        let data = ""

        e.group.sendMsg = (msg) => {
            logger.info(`group 回复内容 = ${msg}`)
        }
        e.reply = async (msg) => {
            logger.info(`reply 回复内容 = ${msg}`)
            if (msg.type == 'image') {
                const fileName = `${uuidv4()}.jpg`
                const filePath = `./web-data/images/${fileName}`
                
                if (msg.file instanceof Buffer) {
                    fs.writeFile(filePath, msg.file, "binary")
                } else if (typeof msg.file == 'string') {
                    if (msg.file.startsWith('file://')) {
                        fs.writeFile(filePath, await fs.readFile(msg.file.replace(/^file:\/\//, '')), "binary")
                    } else if (msg.file.startsWith('base64://')) {
                        fs.writeFile(filePath, Buffer.from(msg.file.replace(/^base64:\/\//, 'base64'), ), "binary")
                    }
                } else {
                    logger.error(`unsupported image type: ${typeof msg.file}`)
                }
                
                fs.writeFile(filePath, msg.file, "binary")
                data += `![img](images/${fileName})\n`
            } else if (typeof msg == 'string') {
                data += `${msg}\n`
            } else {
                logger.error(`unsupported msg: ${msg}`)
            }
        }

        await PluginsLoader.deal(e)

        if (data == "") {
            await new Promise(r => setTimeout(r, 2000)); // sleep 2s
            if (data == "") {
                data = "机器人似乎没有给出回复 :("
            }
        }

        let response = "{}\n" + JSON.stringify({ "text": data })

        logger.info('response = ', response)
        reply.type('application/json').code(200)

        return response
    })


})

fastify.listen({ port: 8080, host: '0.0.0.0' }, (err, address) => {
    if (err) throw err
})
```
### api.rest
```
POST http://localhost:8080/api/chat
Content-Type: application/json

{
    "test": true,
    "self_id": 10000,
    "time": 1676913595310,
    "post_type": "message",
    "message_type": "friend",
    "sub_type": "normal",
    "group_id": 826198224,
    "group_name": "测试群",
    "user_id": 805475874,
    "anonymous": null,
    "message": [
        {
            "type": "text",
            "text": "#帮助"
        }
    ],
    "raw_message": "#uid",
    "font": "微软雅黑",
    "sender": {
        "user_id": 805475874,
        "nickname": "测试",
        "card": "this_is_card",
        "sex": "male",
        "age": 0,
        "area": "unknown",
        "level": 2,
        "role": "owner",
        "title": ""
    },
    "group": {
        "mute_left": 0
    },
    "friend": {},
    "message_id": "JzHU0DACliIAAAD3RzTh1WBOIC48"
}

###

POST http://localhost:8080/api/chat-process
Content-Type: application/json

{"prompt":"#uid","options":{}}
```


