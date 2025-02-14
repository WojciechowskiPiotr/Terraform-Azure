#!/bin/bash
apt-get update
apt-get install -y nginx fcgiwrap curl

# Tworzenie skryptu CGI dla informacji o serwerze DMZ
mkdir -p /usr/lib/cgi-bin
cat <<EOT > /usr/lib/cgi-bin/dmz_info.cgi
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<h1>Server Information (DMZ)</h1>"
echo "<p>IP Address: \$(hostname -I | cut -d' ' -f1)</p>"
echo "<p>Current Date and Time: \$(date)</p>"
EOT
chmod +x /usr/lib/cgi-bin/dmz_info.cgi

# Tworzenie skryptu CGI do pobierania informacji z serwera DB
cat <<EOT > /usr/lib/cgi-bin/get_db_info.cgi
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<p>Połączyłem się z serwerem backend:</p>"
curl -s http://azure-db-vm1/cgi-bin/server_info.cgi
EOT
chmod +x /usr/lib/cgi-bin/get_db_info.cgi

# Konfiguracja Nginx
cat <<EOT > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location /cgi-bin/ {
        gzip off;
        root  /usr/lib;
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    }
}
EOT

# Tworzenie strony HTML
cat <<EOT > /var/www/html/index.html
<!DOCTYPE html>
<html>
<body>
  <div id="dmz-info"></div>
  <hr>
  <div id="db-info"></div>

  <script>
    fetch('/cgi-bin/dmz_info.cgi')
      .then(response => response.text())
      .then(data => {
        document.getElementById('dmz-info').innerHTML = data;
      });

    fetch('/cgi-bin/get_db_info.cgi')
      .then(response => response.text())
      .then(data => {
        document.getElementById('db-info').innerHTML = data;
      });
  </script>
</body>
</html>
EOT

# Restart Nginx i fcgiwrap
systemctl restart nginx
systemctl restart fcgiwrap