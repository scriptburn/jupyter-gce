Please extract the zip file and then go inside extracted folder and run the command : chmod +x spin-jupyter-up
This will make the app executable

then you can run the script like ./spin-jupyter-up 
You can also pass the instance name and instance password like : spin-jupyter-up -n <instance name> -p <instance password>

To see the help message run: spin-jupyter-up -h

it will ask for a default password for jupyter notebook web app , you can enter one or leave it blank and app will auto generate one for you
Aftter command ran successfully you will see a message like:
************** Web interface url: http://<VM IP>:8888/<VM-NAME> with password: <WEB APP PASSWORD> **************

If there is an issue please let me know
script has been tested and developed on Ubuntu 18.04  
