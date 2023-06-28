# Main Setup
*Note before you start: To paste commands into terminal use Ctrl+Shift+v instead of Ctrl+v. Ctrl+v does not work in terminal.*

## Step 1) Install xclip.
Xclip is a package which allows scripts in the terminal to copy from and paste to your system's clipboard.\
*Note: This step is only necessary on Whonix because Tails ships with xclip by default.*

To install xclip, simply open a terminal and run the following command:
```
sudo apt update; sudo apt -y upgrade; sudo apt install -y xclip
```

*Note: If you don't know your sudo password, it is 'changeme' by default on Whonix. If you haven't already it would be a good idea for you to change this to something more secure. You can do this by running the command below. This will prompt you for your current password 'changeme' and then you can set a new one.*\
`passwd`


## Step 2) Create a folder for the DTPA
**On Whonix:**\
Create a folder called 'DarknetTools' in your home folder and navigate to it in terminal by running the command below in terminal:
```
mkdir /home/user/DarknetTools; cd /home/user/DarknetTools
```

**On Tails:**\
Create a folder called 'DarknetTools' in your Persistent folder and navigate to it in terminal by running the command below:
```
mkdir /home/amnesia/Persistent/DarknetTools; cd /home/amnesia/Persistent/DarknetTools
```


## Step 3) Copy the DTPA code to your computer  
Copy the code in the pgpassistant.sh file above to a file called phpassistant.sh in the DarknetTools folder you just created in step 2.


## Step 4) Make the pgpassistant.sh file executable.
This can be done by running the following command:
```
chmod +x pgpassistant.sh
```


## Step 5) Run the pgpassistant.sh script. 
This can be done by running the following command:
```
./pgpassistant.sh
```

*Note: Every time you try running the DTPA again after rebooting your system, remember to navigate back into the DarknetTools folder first in terminal, using the 'cd /home/user/DarknetTools' command on Whonix, or the 'cd /home/amnesia/Persistent/DarknetTools' command on Tails. If you check the 'Useful Tricks & Advanced Options' section at the bottom of this post, you can learn how to simplify running the DTPA.*

*Note: To quit the DTPA, simply press Ctrl+c in the terminal window where it's running.*


# Configuration Options
Here follows a quick recap of all changeable features from the full feature list and how to change them:\
**a)** Do you want the decryption functionality enabled or disabled in the DTPA?

=> Change the 'enableDecryption' variable on line two of the script. Set to 1 for yes, 0 for no. (default: 1)

**b)** (How many days) do you want to store Signed PGP Messages containing a deposit address to protect yourself against selective scamming by markets?

=> Change the 'addressLogTime' variable on line three of the script. Set to 0 to never store them, set to any positive integer for however many days you want to store them. (default: 7 days)

**c)** Do you want to encrypt these Signed Messages containing deposit addresses before storing them?

=> Change the 'addressLogEncryptionKey' variable on line four of the script. Set to the username of your public PGP key. Do not remove the quotes (""). Simply enter the username in between the quotes. Leave the quotes empty to not encrypt these messages. (default: "")

**d)** Do you want all messages that you send out to other people encrypted by the DTPA to also be encrypted for yourself, so you can reread them later?

=> Change the 'encryptForMeKey' variable on line five of the script. Set to the username of your public key. Again, do not remove the quotes. Enter your username in between them. Leave the quotes empty if you do not want to encrypt messages for yourself automatically (default: "")

**e)** How many recent keys do you want shown in the list of possible recipients after decrypting a message from someone in order to type up an encrypted reply to the message?

=> Change the 'recipientListCount' variable on line six of the script. Set to the number of how many keys you want displayed there. (default: 8)

**f)** Do you want the DTPA to stop processing the clipboard if you have Kleopatra open?

=> Change the 'kleopatraLock' variable on line eight of the script. Set to 1 for yes, 0 for no. (default: 0)

**g)** In case you have the kleopatraLock active, do you want to be warned by the DTPA when it stops processing the clipboard?

=> Change the 'kleopatraLockWarning' variable on line nine of the script. Set to 1 for yes, 0 for no. (default: 1)

**h)** Do you want the DTPA's autocorrect function to be enabled to correct PGP blocks in case you miss a few '-' characters during copying them?

=> Change the 'enableAutocorrect' variable on line seven of the script. Set to 1 for yes, 0 for no. (default: 1)

**i)** Do you want the DTPA's certification processing functionality be enabled to automatically allow you to certify keys upon import and/or reject messages that were signed by a key in your keyring that has not yet been certified?

**IMPORTANT: ONLY CHANGE THIS FUNCTIONALITY IF YOU KNOW WHAT YOU'RE DOING!**

=> Change the 'enableCertificationStrictMode' variable on line ten of the script. Set to 1 for yes, which will output an error message for signed messaged when you did not yet certify the public key, 0 for no, which will output a success message if a signed message was signed by a key in your keyring that was not certified alongside a warning of it not being certified yet. (default: 1) 

=> Change the 'enableImportCertification' variable on line ten of the script. Set to 1 for yes to automatically attempt to certify keys upon import, 0 for no, to not try to certify keys upon import. (default: 1)


# Useful Tricks & Advanced Options
**1)** Use Ctrl+w to close the popup text-editor windows. This will make your entire experience a lot smoother than always closing it with your mouse. Ctrl+w should become your new best friend if you're going to be using the DTPA.

**2)** Use Ctrl+a, Ctrl+c for copying the DTPA confirmation messages to clipboard. This will make your entire experience a lot smoother compared to clicking and dragging to select the entire text. 

**3)** You may also run the DTPA in the background, so that you can close the terminal afterwards. This can be done by running the following command in a terminal (once you navigated to the DarknetTools folder first with the 'cd /home/user/DarknetTools' command on Whonix, or 'cd /home/amnesia/Persistent/DarknetTools' on Tails):
```
nohup ./pgpassistant.sh > /tmp/darknet-tools-stdout &
```
*Note: If you run the DTPA in the background, you will no longer be able to quit it with Ctrl+c. You can only quit it then by manually killing the process or by rebooting your system.
To manually kill the DPTA process, open a terminal and run the command 'pgrep -l pgpassistant'. This command will output a number followed by the command you used to start the pgp assistant.
Run the command 'kill -f number' (with number being the number you got back from the pgrep command). This will kill the process and stop the DTPA.*

**4)** You can make things easier for yourself by adding an easy to use alias to your .bashrc file for the DTPA to run in the background. After doing this, you can always run the DTPA in the background by simply typing 'dtpa', or whatever alias you prefer, into a terminal instead of the more complicated commands described earlier.
To do so:\
**On Whonix:**\
Execute the following command in terminal:
```
alias dtpa="nohup /home/user/DarknetTools/pgpassistant.sh > /tmp/darknet-tools-stdout &";echo 'alias dtpa="nohup /home/user/DarknetTools/pgpassistant.sh > /tmp/darknet-tools-stdout &"' >> /home/user/.bashrc
```
You will see the message `nohup: ignoring input and redirecting stderr to stdout`. This indicates that the DTPA is running in the background.

**On Tails:**
- First, make sure your Persistent Storage is set up, and the option to persist dotfiles is checked. If this is not done yet, consult the Tails docs to set this up.
- When dotfiles are persisted, open a terminal and run the following command:
```
alias dtpa="nohup /home/amnesia/Persistent/DarknetTools/pgpassistant.sh > /tmp/darknet-tools-stdout &";echo 'alias dtpa="nohup /home/amnesia/Persistent/DarknetTools/pgpassistant.sh > /tmp/darknet-tools-stdout &"' >> /home/amnesia/.bashrc; cp /home/amnesia/.bashrc /live/persistence/TailsData_unlocked/dotfiles/.bashrc
```
You will see the message `nohup: ignoring input and redirecting stderr to stdout`. This indicates that the DTPA is running in the background.
