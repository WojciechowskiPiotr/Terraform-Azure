#!/bin/bash
apt-get update
apt-get install -y nginx fcgiwrap

# Tworzenie skryptu CGI
mkdir -p /usr/lib/cgi-bin
cat <<EOT > /usr/lib/cgi-bin/server_info.cgi
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<h1>Server Information (Backend)</h1>"
echo "<p>IP Address: \$(hostname -I | cut -d' ' -f1)</p>"
echo "<p>Current Date and Time: \$(date)</p>"
EOT
chmod +x /usr/lib/cgi-bin/server_info.cgi

# Konfiguracja Nginx
cat <<EOT > /etc/nginx/sites-available/default
server {
    listen 80;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name _;
    location / {
        try_files \$uri \$uri/ =404;
    }
    location /cgi-bin/ {
        gzip off;
        root  /usr/lib;
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    }
}
EOT

# Restart Nginx i fcgiwrap
systemctl restart nginx
systemctl restart fcgiwrap