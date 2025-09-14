Reference: https://itsfoss.com/pi-swap-increase/
Step 1: Turn off the current swap
```
sudo dphys-swapfile swapoff
```
Step 2: Edit the swap configuration file
```
sudo nano /etc/dphys-swapfile
```
Step 3: Increase the swap size
```
CONF_SWAPSIZE=2048
```
Step 4: Apply the new swap size
```
sudo dphys-swapfile setup
```
Step 5: Turn the wwap back on
```
sudo dphys-swapfile swapon
```
Step 6: Restart
sudo reboot now
