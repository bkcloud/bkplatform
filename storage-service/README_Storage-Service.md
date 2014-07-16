#BKDatabase

BKDatabase được xây dựng trên Ruby on Rails Framework, deploy sử dụng Passenger Nginx , được cài đặt trên server Centos 6.5
###Installation
####Yêu cầu về các thành phần cần có trước khi cài đặt
**Yêu cầu về hệ điều hành**

OS Centos 6, 64 bit 

**Các thư viện đi kèm**

Ruby 2.0
####Cài đặt Ruby sử dụng RVM trên centos 6.5
    sudo yum groupinstall "Development Tools"
    sudo yum install -y curl-devel mysql-devel
    sudo yum install -y git gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel sqlite-devel mysql-server
    curl -sSL https://get.rvm.io | bash -s stable

    echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm" ' >> ~/.bashrc
    source ~/.bashrc
    # on non-root user
    sudo yum-config-manager --enable epel
    rvm requirements

    #install ruby
    rvm install 1.9.3
    rvm install 2.0.0
    source ~/.rvm/scripts/rvm
    rvm --default use 1.9.3
####Cài đặt Passenger Nginx
    gem install passenger
    rvmsudo `which passenger-install-nginx-module`

    #fix nginx service
    wget —-no-check-certificate https://raw.github.com/kienbd/scripts/master/RoR/centos/nginx
    sudo cp nginx /etc/init.d/nginx
    sudo chmod +x /etc/init.d/nginx
    sudo chkconfig nginx on
    
####Cài đặt các gem
    git clone git@github.com:DxTa/labrador.git ./bkdatabase
    cd bkdatabase
    bundle install

Cấu hình CAS Server trong file **config/config.yml**.

Cấu hình kết nối tới MySQL Cluster trong file **config/initializers/mysql.rb** và kết nối tới Cassandra trong file **config/initializers/cassandra.rb**.

####Tạo database cho production:
    cd bkdatabase
    RAILS_ENV=production rake db:recreate
####Precompile Assets
    RAILS_ENV=production rake assets:precompile
####Cấu hình nginx qua file /opt/nginx/conf/nginx.conf
    …
    user  bkclient;
    worker_processes  1;

    …
    http {
    …
    server {
        listen       8888;
        server_name  localhost;
        charset utf-8;
        root /home/bkclient/bkdatabase/public; #remember the "/public"
        passenger_enabled on;
        rails_spawn_method smart; #
        rails_env production; #config enviroment

        error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   html;
            }
        }
        …   
    }
