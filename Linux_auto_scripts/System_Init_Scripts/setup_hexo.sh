#!/bin/bash
# @Author: 蓝陌
# @Date:   2024-06-29 21:49:06
# @Last Modified time: 
# hexo 博客初始化文件夹

# 检查是否提供了参数
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

DOMAIN=$1

cd /www/wwwroot/

mkdir $DOMAIN

chmod 777 $DOMAIN

cd $DOMAIN

mkdir hexo_blog

git init --bare hexoBlog.git

touch hexoBlog.git/hooks/post-receive

cat>hexoBlog.git/hooks/post-receive <<EOF
#!/bin/bash
git --work-tree=/www/wwwroot/$DOMAIN/hexo_blog --git-dir=/www/wwwroot/$DOMAIN/hexoBlog.git checkout -f
EOF

chmod +x /www/wwwroot/$DOMAIN/hexoBlog.git/hooks/post-receive

chmod 777 -R /www/wwwroot/$DOMAIN/hexoBlog.git
chmod 777 -R /www/wwwroot/$DOMAIN/hexo_blog

chown -R www:www /www/wwwroot/$DOMAIN/

target_user=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')

if [ -n "$target_user" ]; then
    echo "Switching to user: $target_user"
    su - $target_user -c "git config --global --add safe.directory /www/wwwroot/$DOMAIN/hexoBlog.git"
else
    echo "No suitable user found, Run as root user."
    git config --global --add safe.directory /www/wwwroot/$DOMAIN/hexoBlog.git
fi

echo "Setup completed for domain: $DOMAIN"
