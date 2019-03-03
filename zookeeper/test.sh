#!/bash/bin
ip=$(curl -XGET ipinfo.io/ip)
echo $ip >> /home/ubuntu/test-file.txt

