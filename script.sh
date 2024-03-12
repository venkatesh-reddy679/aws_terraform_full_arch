#! /bin/bash

sudo apt update
sudo apt install nginx -y

cat << eof | sudo tee /var/www/html/index.html
<html>
<head>
<h1>venkateswara reddy guduru </h1>
<p>Instance id: $(curl -s http://169.254.169.254/latest/meta-data/instance-id/)</p>
</head>
<body>
</body>
</html>
eof

sudo systemctl start nginx
sudo systemctl enable nginx



