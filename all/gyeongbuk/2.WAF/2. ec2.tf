data "aws_ami" "amazonlinux2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*arm*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon's official account ID
}

resource "aws_instance" "gyeongbuk-private-ec2" {
  ami = data.aws_ami.amazonlinux2023.id
  subnet_id = "${var.private_a}"
  instance_type = "t4g.small"
  key_name = "${var.key_pair}"
  vpc_security_group_ids = [aws_security_group.gyeongbuk-private-sg.id]
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  echo "skills2024" | passwd --stdin ec2-user
  sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
  systemctl restart sshd
  yum install -y curl jq
  yum install -y python3-pip
  cat <<SOS> main.py
  from flask import Flask, request, jsonify, make_response
  import jwt
  import datetime
  import base64
  import json

  app = Flask(__name__)

  SECRET_KEY = 'jwtsecret'

  @app.route('/v1/token', methods=['GET'])
  def get_token():
      payload = {
          'isAdmin': False,
          'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)
      }
      token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
      return jsonify({'token': token})

  @app.route('/v1/token/verify', methods=['GET'])
  def verify_token():
      token = request.headers.get('Authorization')
      if not token:
          return make_response('Token is missing', 403)

      decoded = jwt.decode(token, options={"verify_signature": False})
      isAdmin = decoded.get('isAdmin', False)
      if isAdmin:
          return 'You are admin!'
      else:
          return 'You are not permitted'

  @app.route('/v1/token/none', methods=['GET'])
  def get_none_alg_token():
      payload = {
          'isAdmin': True,
          'exp': (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)).timestamp()
      }

      header = {
          'alg': 'none',
          'typ': 'JWT'
      }

      encoded_header = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
      encoded_payload = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")

      token = f"{encoded_header}.{encoded_payload}."
      return jsonify({'token': token})

  @app.route('/healthcheck', methods=['GET'])
  def health_check():
      return make_response('ok', 200)

  if __name__ == '__main__':
      app.run(host='0.0.0.0', debug=True)
  SOS
  echo "flask==3.0.3" >> ./requirements.txt
  echo "pyjwt==2.8.0" >> ./requirements.txt
  pip install --no-cache-dir -r ./requirements.txt
  sudo FLASK_APP=main.py nohup flask run --host=0.0.0.0 --port=80 &

  EOF
  tags = {
    Name = "wsi-token-1"
  }
}
## private Security Group
resource "aws_security_group" "gyeongbuk-private-sg" {
  name = "wsi-token-sg"
  vpc_id = "${var.vpc}"

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.gyeongbuk-lb-sg.id]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }
    tags = {
    Name = "wsi-token-sg"
  }
}

resource "aws_lb" "gyeongbuk-alb" {
  name               = "wsi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gyeongbuk-lb-sg.id]
  subnets            = ["${var.public_a}", "${var.public_b}"]
  tags = {
    Name = "wsi-alb"
  }
}

resource "aws_alb_target_group" "gyeongbuk-token" {
  name     = "token-targate-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc}"

  health_check {
    interval            = 5
    path                = "/healthcheck"
    healthy_threshold   = 2
    timeout = 4
    unhealthy_threshold = 2
  }
  tags = {
    Name = "token-targate-group"
  }
}

resource "aws_alb_target_group_attachment" "gyeongbuk-token-1" {
  target_group_arn = aws_alb_target_group.gyeongbuk-token.arn
  target_id        = aws_instance.gyeongbuk-private-ec2.id
  port             = 80
}

resource "aws_alb_listener" "gyeongbuk-http" {
  load_balancer_arn = aws_lb.gyeongbuk-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gyeongbuk-token.arn
    type             = "forward"
  }
}


## private Security Group
resource "aws_security_group" "gyeongbuk-lb-sg" {
  name = "alb-sg"
  vpc_id = "${var.vpc}"
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
    tags = {
    Name = "alb-sg"
  }
}