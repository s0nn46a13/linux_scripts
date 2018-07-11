sudo wget -c https://ftp.drupal.org/files/projects/drupal-8.5.5.tar.gz
sudo tar -zxvf drupal-8.5.5.tar.gz
cd drupal-8.5.5
sudo rm -rf modules
sudo rm -rf sites
yes | sudo cp -rf * /var/www/html/drupal
