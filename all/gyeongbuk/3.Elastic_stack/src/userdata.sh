#!/bin/bash
yum update -y
yum install -y jq curl wget
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
ln -s /usr/local/bin/aws /usr/bin/
ln -s /usr/local/bin/aws_completer /usr/bin/
sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo "Skill53##" | passwd --stdin ec2-user
echo "Skill53##" | passwd --stdin root
yum install -y python3-pip
pip3 install flask
cat <<EOF> /home/ec2-user/app.py
from flask import Flask, request
import logging
import time
import os

app = Flask(__name__)

log_dir = 'log'
log_file = 'app.log'

if not os.path.exists(log_dir):
    os.makedirs(log_dir)

formatter = logging.Formatter('%(message)s')

file_handler = logging.FileHandler(os.path.join(log_dir, log_file))
file_handler.setFormatter(formatter)

logger = logging.getLogger('customLogger')
logger.setLevel(logging.INFO)

logger.addHandler(file_handler)

def log_request_info():
    client_ip = request.remote_addr
    timestamp = time.strftime('%d/%b/%Y:%H:%M:%S %z')
    method = request.method
    path = request.path
    protocol = request.environ.get('SERVER_PROTOCOL')
    status_code = 200
    user_agent = request.headers.get('User-Agent')

    log_message = (f'{client_ip} - [{timestamp}] "{method} {path} {protocol}" '
                   f'{status_code} "{user_agent}"')

    logger.info(log_message)

@app.route('/log', methods=['GET'])
def log_request():
    log_request_info()
    return "Log entry created", 200

@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    log_request_info()
    return "status: ok", 200

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0')
EOF
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
sudo systemctl enable --now fluent-bit
sudo ln -s /opt/fluent-bit/bin/fluent-bit /bin/
mkdir /home/ec2-user/log
python3 /home/ec2-user/app.py 2>&1 &
cat <<\EOF>> /etc/fluent-bit/fluent-bit.conf
[INPUT]
    Name tail
    Path /home/ec2-user/log/app.log
    Tag wsi.app.log
[FILTER]
    Name parser
    Match wsi.app.*
    Key_Name log
    Parser logParser
[FILTER]
    Name        grep
    Match       wsi.app.*
    Exclude      path /.*healthcheck.*/
    Exclude      path /.*healthcheck.*
    Exclude      path .*healthcheck.*
[OUTPUT]
    Name            es
    Match           wsi.app.*
    Host            ES_EP
    Port            443
    TLS             On
    AWS_Auth        On
    AWS_Region      ap-northeast-2
    Index           app-log
    Replace_Dots    On
    Suppress_Type_Name On
EOF
ES_EP=$(aws opensearch describe-domain --domain wsi-opensearch --query "DomainStatus.Endpoint" --output text)
sed -i "s|ES_EP|$ES_EP|g" /etc/fluent-bit/fluent-bit.conf
cat <<\SOS>> /etc/fluent-bit/parsers.conf
[PARSER]
    Name logParser
    Format regex
    Regex ^(?<clientip>[^ ]*) - \[(?<time>[^\]]*)\] "(?<method>[^ ]*) (?<path>[^ ]*) (?<protocol>[^ ]*)" (?<responsecode>[^ ]*) \S\S(?<useragent>[^"]*)\S
SOS
systemctl restart fluent-bit
nohup fluent-bit -c /etc/fluent-bit/fluent-bit.conf > /dev/null 2>&1 &